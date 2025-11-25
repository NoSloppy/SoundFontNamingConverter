<p>If this tool helps you, donations are appreciated ;) <a href="https://www.buymeacoffee.com/brianconner">Buy me a coffee</a></p>  

This is the OLD repo. New version found here:  
https://github.com/NoSloppy/SoundFontNamingConverter5/tree/master


Current version live and up here:  
https://www.soundfontnamingconverter.com  

Automated cross conversion of saber sound font naming conventions between popular controller boards:  
Proffieboard, CFX, Golden Harvest 3, Verso, and Xenopixel 3.    
No need to manually rename a font (or many fonts) so it can be used on a different platform. Just click and done.  

Automatically converts audio files if the source is not in optimal 44.1kHz, 16 bit, monaural PCM WAV file format.  
Proffie to Proffie conversions organize and rename a ProffieOS sound font for the best performance when used on FAT32 formatted media.  
The Optimize checkbox is also on by default for other boards to Proffie conversions, but can be turned off. (but why?)  

Usage: Super easy. Barely an inconvenience.  

- Choose a source and target sound board format.  
- Choose a font folder from your local computer.  
- Click the Convert button.  
- Click the Download button to retrieve a zip file containing the newly named font files.
- Option to Convert Audio Only - file structure remains unchanged, but all audio (even from mp4 video files) gets converted for use on saber boards. 

Click the Version Changelog button at the bottom of the page to see incremental updates.

## *NEW - Running Locally with Docker

1. Install Docker Desktop  
Download and install Docker Desktop (https://www.docker.com/products/docker-desktop/).  
Windows & Mac: Just install and run it.  
Linux: Install via package manager (apt, yum, etc.).  

2. Build and Run the App  
Open a terminal and run:
```
docker build -t soundfontconverter .
docker run -p 8080:8080 soundfontconverter
```  
3. Open a browser and go to:
 http://localhost:8080/  
Enjoy!
