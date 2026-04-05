import triton_python_backend_utils as pb_utils
import json
from pathlib import Path
from utils.misc import load_config, make_logger, set_seed, neq_load_customized
import torch
import numpy as np
from modelling.model import build_model


class TritonPythonModel:

    @staticmethod
    def auto_complete_config(auto_complete_model_config: pb_utils.ModelConfig):
        """`auto_complete_config` is called only once when loading the model
        assuming the server was not started with
        `--disable-auto-complete-config`. Implementing this function is
        optional. No implementation of `auto_complete_config` will do nothing.
        This function can be used to set `max_batch_size`, `input` and `output`
        properties of the model using `set_max_batch_size`, `add_input`, and
        `add_output`. These properties will allow Triton to load the model with
        minimal model configuration in absence of a configuration file. This
        function returns the `pb_utils.ModelConfig` object with these
        properties. You can use the `as_dict` function to gain read-only access
        to the `pb_utils.ModelConfig` object. The `pb_utils.ModelConfig` object
        being returned from here will be used as the final configuration for
        the model.

        Note: The Python interpreter used to invoke this function will be
        destroyed upon returning from this function and as a result none of the
        objects created here will be available in the `initialize`, `execute`,
        or `finalize` functions.

        Parameters
        ----------
        auto_complete_model_config : pb_utils.ModelConfig
          An object containing the existing model configuration. You can build
          upon the configuration given by this object when setting the
          properties for this model.

        Returns
        -------
        pb_utils.ModelConfig
          An object containing the auto-completed model configuration
        """
        inputs = [{
            'name': 'CLIP',
            'data_type': 'TYPE_UINT8',
            'dims': [-1, 3, -1, -1]  # T, 3, H, W RGB
        }, {
            'name': 'KEYPOINTS',
            'data_type': 'TYPE_FP32',
            'dims': [-1, -1, 3]      # T, K, 3
        }]

        config = auto_complete_model_config.as_dict()
        input_names = []
        for input in config['input']:
            input_names.append(input['name'])

        for input in inputs:
            if input['name'] not in input_names:
                auto_complete_model_config.add_input(input)

        if not config['max_batch_size']:
            auto_complete_model_config.set_max_batch_size(16)

        return auto_complete_model_config

    def initialize(self, args):
        """`initialize` is called only once when the model is being loaded.
        Implementing `initialize` function is optional. This function allows
        the model to initialize any state associated with this model.

        Parameters
        ----------
        args : dict
          Both keys and values are strings. The dictionary keys and values are:
          * model_config: A JSON string containing the model configuration
          * model_instance_kind: A string containing model instance kind
          * model_instance_device_id: A string containing model instance device
            ID
          * model_repository: Model repository path
          * model_version: Model version
          * model_name: Model name
        """
        model_config = json.loads(args["model_config"])

        model_dir = Path(__file__).resolve().parent

        self.logger = make_logger()

        set_seed(8)

        cslr_cfg_path = model_dir / model_config["parameters"]["cslr_config"]["string_value"]
        cfg = load_config(cslr_cfg_path)

        cfg['model']['RecognitionNetwork']['s3d']['pretrained_ckpt'] = str((model_dir / cfg['model']['RecognitionNetwork']['s3d']['pretrained_ckpt']).absolute())
        cfg['model']['RecognitionNetwork']['keypoint_s3d']['pretrained_ckpt'] = str((model_dir / cfg['model']['RecognitionNetwork']['keypoint_s3d']['pretrained_ckpt']).absolute())

        if args['model_instance_kind'] == 'GPU':
            device_id = args['model_instance_device_id']
            self.device = torch.device(f'cuda:{device_id}')
        else:
            self.device = torch.device('cpu')
        cfg['device'] = self.device
       
        num_classes = model_config['output'][0]['dims'][0]
        logger = pb_utils.Logger
        logger.log_info(f'num classes = {num_classes}')
        self.model = build_model(cfg, num_classes, word_emb_tab=None)

        ckpt_path = model_dir / cfg['model']['RecognitionNetwork']['cslr']['pretrained_ckpt']
        state_dict = torch.load(ckpt_path, map_location=self.device)
        neq_load_customized(self.model, state_dict['model_state'], verbose=True)
        self.epoch = state_dict.get('epoch', 0)
        self.logger.info(f'Model ckpt loaded from {ckpt_path} with epoch={self.epoch}')
        self.model.eval()

        self.win_size = cfg['data'].get('win_size', 16)
        self.label = torch.tensor([0]).long().to(self.device)


    def execute(self, requests):
        """`execute` must be implemented in every Python model. `execute`
        function receives a list of pb_utils.InferenceRequest as the only
        argument. This function is called when an inference is requested
        for this model.

        Parameters
        ----------
        requests : list
          A list of pb_utils.InferenceRequest

        Returns
        -------
        list
          A list of pb_utils.InferenceResponse. The length of this list must
          be the same as `requests`
        """

        all_frames = []
        all_keypoints = []
        cancelled_indices = []
        for i, request in enumerate(requests):
            if request.is_cancelled():
                cancelled_indices.append(i)
                continue

            frames_inp = pb_utils.get_input_tensor_by_name(request, 'CLIP')
            all_frames.append(frames_inp.as_numpy())
            keypoints_inp = pb_utils.get_input_tensor_by_name(request, 'KEYPOINTS')
            all_keypoints.append(keypoints_inp.as_numpy())

        batched_frames = torch.from_numpy(np.concatenate(all_frames, axis=0)).float().div(255.0).cuda(device=self.device).contiguous()
        batched_keypoints = torch.as_tensor(np.concatenate(all_keypoints, axis=0), device=self.device)
        
        # logger = pb_utils.Logger
        # logger.log_info(f'win frame shape = {batched_frames.shape}')
        # logger.log_info(f'win kp shape = {batched_keypoints.shape}')

        with torch.inference_mode():
            forward_output = self.model(is_train=False, labels=self.label, sgn_videos=[batched_frames], sgn_keypoints=[batched_keypoints], epoch=self.epoch)
        batched_output = forward_output['ensemble_last_gloss_logits']

        cur_idx = 0 # current valid input index
        offset = 0
        responses = []
        num_requests = len(requests)
        for i in range(num_requests):
            if i in cancelled_indices:
                responses.append(pb_utils.InferenceResponse(
                    error=pb_utils.TritonError("Request cancelled", pb_utils.TritonError.CANCELLED)))
                continue
        
            batch_size = all_frames[cur_idx].shape[0]
            individual_output = batched_output[offset:offset+batch_size]
            cur_idx += 1
            offset += batch_size
            out_tensor = pb_utils.Tensor.from_dlpack('GLOSS', torch.to_dlpack(individual_output.contiguous()))
            inference_response = pb_utils.InferenceResponse(output_tensors=[out_tensor])
            responses.append(inference_response)
        
        return responses
