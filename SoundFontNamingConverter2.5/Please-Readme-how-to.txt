Welcome to the multi-board soundfont naming conversion tool.
- by r/Mormegil, modified by r/NoSloppy.

This tool will convert from:
CFX to Proffie
CFX to Xenopixel
Proffie to CFX
Proffie to Xenopixel
Xenopixel to CFX
Xenopixel to Proffie

It will save the converted soundfonts in a new folder named "Converted_to_X", where X is the board you chose to convert to.
The tool should explain itself when being used.
Demo Video here (preliminary version):
https://www.youtube.com/watch?v=O8kTYt0KenQ

While this can run from anywhere, it might be easiest to just move a copy of the font you want to convert into the folder with the tool files.
See example below.

Starting the tool:
-----------------
Windows:
- Double click on "SoundFontNamingConverter.bat".

MacOS:
- Double click "SoundFontNamingConverter.command".


I suggest making a copy of the Font to convert and drag into the folder next to convert.sh., or use the template folders included.

Step 1, answer the questions.
You have choices for which format to convert from -> to.
They are abbreviated logically, so
- CtoG is CFX to GoldenHarvest
- PtoC is Proffie to CFX
- PtoP is Proffie to Proffie 
and so on.

-----------------------------
Exemplary folder structure:

.../SoundfontNamingConverter
	|_Proffie
	.	|_SoundfontMaker 1
	.		|_Font 1
	.		|_Font 2
	.	|_SoundfontMaker 2
	.		|_Font 1
	.	|_SoundfontMaker 3
	.		|_Font 1
	|_CFX
	convert.sh
	ReadMe.txt
	SoundFontConverter.bat
	
In this example, we have a folder named 'Proffie' containing Proffie fonts,
and a folder full of CFX fonts in the folder with the tool.
- To convert all Proffie fonts of one SoundfontMaker at the same time,
  you'd choose option 2, and enter the name of the folder containing the fonts to convert, in this case, 'SoundfontMaker 1'.
Font 1 and Font 2 will be processed and placed in a folder named "Converted to X", where X is the board you chose in step 1.

Alternatively you can choose to only convert one soundfont and then specifying the path to the actual font folder. If you moved the font into the same folder as the working tool directory (as Font 4 above shows), then the path is simply the font folder name
Font4
If You want to convert one font but it is inside a subfolder (like a folder named for the font maker, character, other), then the path would be "SoundfontMaker X/Font X". 

NOTE: If you select to only convert one soundfont and then specify "SoundfontMaker 1" as the folder for example, 
all the Fonts will be converted and mixed into one giant (probably pretty weird) soundfont called "SoundfontMaker 1".
If you put the tool in "Soundfonts" and selected "Proffie" as the folder to be converted, something similar would happen. 
Depending on your selection of one or several fonts to be converted you'd get a giant "Proffie" soundfont or several 
"SoundfontMaker X" soundfonts. 

So please remember that this tool is useful, but not idiot-proof!

If you encounter any issues, please contact Mormegil#4775 or NoSloppy#4203 on the lightsaber discord:
discord.gg/lightsabers,
Or reach out to Brian Conner on Facebook/Open Source Sabers group.


PtoP functionality:
Script will copy over any files in the font root that are not renamed/organized sounds. This includes .ini files, .txt, .bmp images, styles in .h files...anything not .wav.
*Note that if you have other stored files in subfolders (like an Extras folder), these will need to be handled manually, as they are not really core font contents anyway.
 
If your source font was missing a config.ini or smoothsw.ini file, the default versions of them will be added for you. (⌐■_■)

