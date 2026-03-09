import warnings
from modelling.model import build_model
warnings.filterwarnings("ignore")
import os
import json
import torch
from utils.misc import (
    get_logger,
    neq_load_customized,
)

class PredictionSource:
    ENSEMBLE = 0
    FUSE = 1

class OnlineCSLRInferencer:
    def __init__(self, cfg: dict, ckpt_name: str, pred_src: PredictionSource = PredictionSource.ENSEMBLE):
        self.device = cfg['device']
        self.win_size = cfg['data'].get('win_size', 16)        
        model_dir = cfg['training']['model_dir']
        
        with open(cfg['data']['vocab_file'], 'rb') as f:
            vocab = json.load(f)    
        
        cls_num = len(vocab)
        self.model = build_model(cfg, cls_num, word_emb_tab=None)

        if '<blank>' in vocab:        
            blank_id = vocab.index('<blank>')
        else:        
            blank_id = cls_num
            vocab.append('<blank>')        
        self.vocab = vocab
        self.blank_id = blank_id

        load_model_path = os.path.join(model_dir, ckpt_name)
        logger = get_logger()
        assert os.path.isfile(load_model_path), f'{load_model_path} does not exist'
        state_dict = torch.load(load_model_path, map_location='cuda')
        neq_load_customized(self.model, state_dict['model_state'], verbose=True)
        self.epoch = state_dict.get('epoch', 0)
        logger.info(f'Load model ckpt from {load_model_path} with epoch={self.epoch}')
        self.pred_src = pred_src

        self.model.eval()  
        
        self.label = torch.tensor([0]).long().to(self.device)

    def warm_up(self, steps=1, batch_size=16, window_size=16, height=260, width=210, keypoint_count=63, use_augmentation=False):
        dummy_video = torch.rand(batch_size, window_size, 3, height, width, dtype=torch.float32, device=self.device)
        dummy_keypoints = torch.rand(batch_size, window_size, keypoint_count, 3, dtype=torch.float32, device=self.device)        

        if not use_augmentation:
            sgn_videos = [dummy_video]
            sgn_keypoints = [dummy_keypoints]
        else:
            sgn_videos = [dummy_video]
            sgn_videos.append(sgn_videos[-1][:, self.win_size//4:self.win_size//4+self.win_size//2, ...].contiguous())
            sgn_keypoints = [dummy_keypoints]
            sgn_keypoints.append(sgn_keypoints[-1][:, self.win_size//4:self.win_size//4+self.win_size//2, ...].contiguous())        

        with torch.inference_mode():
            for _ in range(steps):
                self.model(is_train=False, labels=self.label, sgn_videos=sgn_videos, sgn_keypoints=sgn_keypoints, epoch=self.epoch)
        torch.cuda.synchronize(device=self.device)


    def infer(self, video: torch.Tensor, keypoints: torch.Tensor, use_augmentation=False) -> torch.Tensor:
        """
        CSLR inference.

        Arguments:  
            video (Tensor): shape [B, T, 3, H, W]
            keypoints (Tensor): shape [B, T, K, 3]            

        Returns:
            gloss logits, shape [B, cls_num].
        """
        with torch.inference_mode():
            if not use_augmentation:
                sgn_videos = [video]
                sgn_keypoints = [keypoints]
            else:
                sgn_videos = [video]
                sgn_videos.append(sgn_videos[-1][:, self.win_size//4:self.win_size//4+self.win_size//2, ...].contiguous())
                sgn_keypoints = [keypoints]
                sgn_keypoints.append(sgn_keypoints[-1][:, self.win_size//4:self.win_size//4+self.win_size//2, ...].contiguous())        
            
            forward_output = self.model(is_train=False, labels=self.label, sgn_videos=sgn_videos, sgn_keypoints=sgn_keypoints, epoch=self.epoch)

            if self.pred_src == PredictionSource.ENSEMBLE:
                gls_logits = forward_output['ensemble_last_gloss_logits']
            else:
                gls_logits = forward_output['fuse_gloss_logits']        
            # print(f'OUTPUT DTYPE: {gls_logits.dtype}')

            # print(f'out device: {gls_logits.device}')
            return gls_logits # [B, cls_num]
    
    def predict_gloss_from_logits(self, gls_logits: torch.Tensor, k: int = 10):
        return self.model.predict_gloss_from_logits(gloss_logits=gls_logits, k=k)  #[1,K]
    
    def index2gloss(self, index: int):
        return map_phoenix_gls(self.vocab[index])    

def map_phoenix_gls(g_lower):#lower->upper
    if 'neg-' in g_lower[:4]:
        g_upper = 'neg-'+g_lower[4:].upper()
    elif 'poss-' in g_lower:
        g_upper = 'poss-'+g_lower[5:].upper()
    elif 'negalp-' in g_lower:
        g_upper = 'negalp-'+g_lower[7:].upper()
    elif 'loc-' in g_lower:
        g_upper = 'loc-'+g_lower[7:].upper()
    elif 'cl-' in g_lower:
        g_upper = 'cl-'+g_lower[7:].upper()
    else:
        g_upper = g_lower.upper()
    return g_upper
