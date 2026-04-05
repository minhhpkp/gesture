import triton_python_backend_utils as pb_utils
from pathlib import Path
from mmdeploy_runtime import Detector
import numpy as np

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
            'name': 'IMAGES',
            'data_type': 'TYPE_UINT8',
            'dims': [-1, -1, -1, 3],    # B, H, W, 3
        }]
        outputs = [{
            'name': 'BBOXES',           # all detections concatenated
            'data_type': 'TYPE_FP32',
            'dims': [-1, 5]             # N, 5
        }, {
            'name': 'BBOX_COUNTS',      # number of detections per image
            'data_type': 'TYPE_INT32',
            'dims': [-1]                # B
        }]

        config = auto_complete_model_config.as_dict()
        input_names = []
        output_names = []
        for input in config['input']:
            input_names.append(input['name'])
        for output in config['output']:
            output_names.append(output['name'])

        for input in inputs:
            if input['name'] not in input_names:
                auto_complete_model_config.add_input(input)
        for output in outputs:
            if output['name'] not in output_names:
                auto_complete_model_config.add_output(output)

        if not config['max_batch_size']:
            auto_complete_model_config.set_max_batch_size(0)

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
        model_dir = Path(__file__).resolve().parent
        model_dir_str = str(model_dir.absolute())

        if args['model_instance_kind'] == 'GPU':
            device_name = 'cuda'
            device_id = int(args['model_instance_device_id'])
        else:
            device_name = 'cpu'
            device_id = 0

        self.detector = Detector(
            model_path=model_dir_str,
            device_name=device_name,
            device_id=device_id
        )


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

        num_requests = len(requests)
        all_images = []
        responses = [None] * num_requests
        for i, request in enumerate(requests):
            if request.is_cancelled():
                responses[i] = pb_utils.InferenceResponse(
                    error=pb_utils.TritonError("Request cancelled", pb_utils.TritonError.CANCELLED)
                )
                continue

            image_input = pb_utils.get_input_tensor_by_name(request, 'IMAGES')
            image_np = image_input.as_numpy()
            all_images.append(image_np)

        batched_images = np.concatenate(all_images, axis=0)
        batched_output = self.detector.batch(batched_images)

        cur_idx = 0 # current valid input index
        offset = 0
        for i in range(num_requests):
            if responses[i] is not None:
                continue

            batch_size = all_images[cur_idx].shape[0]
            bboxes = []
            bbox_counts = []
            for out_idx in range(offset, offset+batch_size):
                boxes, labels, _ = batched_output[out_idx]
                # return only human results (class 0)
                human_boxes = boxes[labels == 0]
                bboxes.append(human_boxes)
                bbox_counts.append(human_boxes.shape[0])
            cur_idx += 1
            offset += batch_size
            bboxes_np = np.concatenate(bboxes, axis=0)
            bbox_counts_np = np.stack(bbox_counts, axis=0)
            out_bboxes = pb_utils.Tensor("BBOXES", bboxes_np)
            out_bbox_counts = pb_utils.Tensor("BBOX_COUNTS", bbox_counts_np)
            responses[i] = pb_utils.InferenceResponse(output_tensors=[out_bboxes, out_bbox_counts])

        return responses


    def finalize(self):
        """`finalize` is called only once when the model is being unloaded.
        Implementing `finalize` function is optional. This function allows
        the model to perform any necessary clean ups before exit.
        """
        # guard against the case where initialize may have failed before self.detector was assigned
        if hasattr(self, 'detector'):
            # explicitly delete the detector
            del self.detector