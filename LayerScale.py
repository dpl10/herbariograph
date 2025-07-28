import tensorflow as tf

### LAYER SCALE (ARXIV:2103.17239)
class LayerScale(tf.keras.layers.Layer):
	def __init__(self, epsilon = 0.1, **kwargs):
		super().__init__(**kwargs)
		self.epsilon = epsilon
	def build(self, input_shape):
		self.gamma = self.add_weight(
			initializer = tf.keras.initializers.Constant(self.epsilon),
			shape = (input_shape[-1],),
			trainable = True
		)
	def call(self, inputs):
		return inputs*self.gamma
	def get_config(self):
		config = super().get_config()
		config.update({"epsilon": self.epsilon})
		return config
