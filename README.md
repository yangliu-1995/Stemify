# Stemify

🎵 **Stemify** — An open-source iOS app for offline music source separation.  
Built with C++ and TensorFlow Lite, Stemify brings [Spleeter](https://github.com/deezer/spleeter)’s vocal/accompaniment separation to iOS.  
Inspired by [jinay1991/spleeter](https://github.com/jinay1991/spleeter), it leverages a sliding-window approach to efficiently handle limited mobile memory, enabling high-quality separation on iOS devices.

## Getting Started

1. **Clone the Repository**  
   ```bash
   git clone https://github.com/yourusername/Stemify.git
   cd Stemify
   ```

2. **Download Model Files**
   Download the `.tflite` model files from [jinay1991/spleeter releases](https://github.com/jinay1991/spleeter/releases) and unzip them to: `$(SRCROOT)/Stemify/Spleeter/Core/TFModels/`

   Example:

   ```
   Stemify/Spleeter/Core/TFModels/2stems.tflite
   ```

3. **Build TensorFlow Lite**
   Follow the official instructions to build TensorFlow Lite for iOS:

   * [Build TensorFlow Lite for iOS](https://ai.google.dev/edge/litert/build/ios)
   * [Selectively build TFLite frameworks](https://ai.google.dev/edge/litert/build/ios#selectively_build_tflite_frameworks)

   After building, copy the following frameworks to your project:

   ```
   $(SRCROOT)/Stemify/Spleeter/third-party/
   ```

   * `TensorFlowLiteC.framework`
   * `TensorFlowLiteSelectTfOps.framework`

4. **FFmpeg Integration**
   FFmpeg is integrated via Swift Package Manager (version 6.0).
   You can also integrate FFmpeg using other methods if preferred.

## Usage

* Open the project in Xcode.
* Select a music file using the file picker.
* Tap **Start Processing** to separate vocals and accompaniment.
* Progress and status will be displayed during processing.

## License

The Spleeter code is licensed under GPL.

## References

* Deezer Research – Source Separation Engine Story:

  * [English](https://deezer.io/releasing-spleeter-deezer-r-d-source-separation-engine-2b88985e797e)
* Music Source Separation Tool with Pre-trained Models – ISMIR 2019 Extended Abstract:
  [PDF](http://archives.ismir.net/ismir2019/latebreaking/000036.pdf)

If you use **Spleeter** in your work, please cite:

```bibtex
@misc{spleeter2019,
  title={Spleeter: A Fast And State-of-the Art Music Source Separation Tool With Pre-trained Models},
  author={Romain Hennequin and Anis Khlif and Felix Voituret and Manuel Moussallam},
  howpublished={Late-Breaking/Demo ISMIR 2019},
  month={November},
  note={Deezer Research},
  year={2019}
}
```

* [jinay1991/spleeter](https://github.com/jinay1991/spleeter)
