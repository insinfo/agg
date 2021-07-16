import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi_utils/ffi_utils.dart';
import 'package:glfw/glfw.dart';
import 'package:opengl/opengl.dart';
import 'package:ffi/ffi.dart';

const int IMAGE_WIDTH = 640; // número de colunas da imagem.
const int IMAGE_HEIGHT = 480; // número de linhas da imagem.

Pointer<Uint32> textures;

void main() {
  //// load GLFW dynamic library and init all its functions
  initGlfw();
  glfwInit();
  print('GLFW: ${Utf8.fromUtf8(glfwGetVersionString().cast<Utf8>())}');

  final window = glfwCreateWindow(IMAGE_WIDTH, IMAGE_HEIGHT, Utf8.toUtf8('Dart FFI + GLFW + OpenGL'), nullptr, nullptr);
  glfwMakeContextCurrent(window);

  // load OpenGL dynamic library and init all its functions
  initOpenGL();
  print('GL_VENDOR: ${Utf8.fromUtf8(glGetString(GL_VENDOR).cast<Utf8>())}');
  print('GL_RENDERER: ${Utf8.fromUtf8(glGetString(GL_RENDERER).cast<Utf8>())}');
  print('GL_VERSION: ${Utf8.fromUtf8(glGetString(GL_VERSION).cast<Utf8>())}');

  prepare();

  while (glfwWindowShouldClose(window) != GLFW_TRUE) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glfwSwapBuffers(window);
    glfwPollEvents();
  }
}

void prepare() {
  //unsigned char * FBptr;
  // Aloca o framebuffer e inicializa suas posições com 0.
  //FBptr = new unsigned char[IMAGE_WIDTH * IMAGE_HEIGHT * 5];
  var FBptr = List<int>.filled(IMAGE_WIDTH * IMAGE_HEIGHT * 5, 0);
  for (int i = 0; i < IMAGE_WIDTH * IMAGE_HEIGHT; i++) {
    FBptr[i * 4] = 0;
    FBptr[i * 4 + 1] = 0;
    FBptr[i * 4 + 2] = 0;
    FBptr[i * 4 + 3] = 255;
  }
  var textureData = Uint8List.fromList(FBptr);
  glClearColor(0.0, 0.7, 0.99, 0.0);
  glViewport(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
  // Cria uma textura 2D, RGBA (8 bits por componente).
  textures = allocate<Uint32>();
  glGenTextures(1, textures);
  glBindTexture(GL_TEXTURE_2D, textures[0]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 600, 400, 0, GL_RGB, GL_FLOAT, pixels);
  //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, IMAGE_WIDTH, IMAGE_HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, FBptr as Pointer);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, IMAGE_WIDTH, IMAGE_HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE,
      NativeBuffer.fromTyped(textureData));
  //glBindTexture(GL_TEXTURE_2D, 0);
}
