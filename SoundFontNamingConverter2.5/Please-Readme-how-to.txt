# SoundFontNamingConverter
Script to automate renaming cross-platform saber sound fonts.

Welcome to the multi-board soundfont renaming conversion tool!
- by r/Mormegil, modified by r/NoSloppy.

This tool will convert from:  
Proffie to (proper) Proffie, including adding .ini files for you  
CFX to GoldenHarvest  
CFX to Xenopixel  
Proffie to CFX  
Proffie to GoldenHarvest  
Proffie to Xenopixel  
Xenopixel to CFX  
Xenopixel to GoldenHarvest  

The converted soundfonts are placed in a new folder named 'Converted_to_'X'',  
where X is the board you chose to convert to.   
Demo Video here (preliminary version): https://www.youtube.com/watch?v=O8kTYt0KenQ  
While this can run from anywhere, it might be easiest to just move a copies of the fonts you want to convert  
into the SoundFontNamingConverter folder with the tool files.  
See example below.

*NOTE!!* -- It is highly recommended you DO NOT USE SPACES in any folder or filenames  
when dealing with fonts. Use underscores instead.

Starting the tool:
-----------------
Windows:
- Double click on 'SoundFontNamingConverter.bat'.

MacOS:
- Double click 'SoundFontNamingConverter.command'.

Converting:
-----------------
Step 1: Chose which format to convert from -> to.
They are abbreviated logically, so
- CtoG is CFX to GoldenHarvest
- PtoC is Proffie to CFX
- PtoP is Proffie to Proffie  
and so on.

*Note PtoP functionality:  
Script will copy and bring over any files in the font root that are not renamed/organized sounds.  
This includes .ini files, .txt, .bmp images, styles in .h files...anything not .wav.  
However, if you have other stored files in subfolders (like an 'Extras' folder),  
these will need to be handled manually, as they are not really core font contents anyway.  
Additional bonus - If your source font was missing a config.ini or smoothsw.ini file,  
the default versions of them will be added for you. ;)

-----------------------------
Exemplary folder structure:
```
.../SoundFontNamingConverter
	|_CFX
	|_Font4
	|_inis
	|_Proffie
	.	|_SoundfontMakerA
	.		|_Font1_Proffie (This is the actual font folder that contains all the sounds)
	.		|_Font2_Proffie
	convert.sh
	Please-Readme-how-to.txt
	SoundFontNamingConverter.bat
	SoundFontNamingConverter.command
```
In this example, we have a folder named 'Proffie' containing Proffie fonts,  
a folder full of CFX fonts,  
and 'Font4' which has been copied directly into the SoundFontNamingConverter folder  
(where you ARE when running the tool).
	
Step 2: Process a single or multiple fonts at once.
- Single - Choose option 1, then enter the path to the actual font folder.  
If you copied your font into the same folder as the working tool directory (as 'Font4' above shows),  
then the path is simply the font folder name:`Font4`  
If the target font is inside 1 subfolder (like a folder named for the font maker, character, other),  
then the path might be something like `Luke/The_Return`.  
In our example above, a valid single font conversion path would be  
`Proffie/SoundfontMakerA/Font2_Proffie`.

- Multiple at the same time -  
Choose option 2, then enter the path to the FOLDER CONTAINING the fonts to convert,  
In our example above, a valid multiple font conversion path would be `Proffie/SoundfontMakerA`.  
Notice that the path stops one level earlier because our target is the folder containing the multiple fonts.  
Font1_Proffie and Font2_Profiie would be processed and placed in a folder named 'Converted_to_'X'',  
where X is the board you chose in step 1.

Once the converted version is finished and in the 'Converted_to_'X'' folder, you are free to delete the source  
you converted from, which in our example here would be everything within the  
'SoundFontNamingConverter/Proffie' folder.  
(it's just copies that you brought over from your safe font library/collection stored somewhere else....right??)

NOTE: Please understand the differences of the correct paths as described above.  
Using an incomplete path will cause everything beneath to converted and mixed into one giant  
(and probably pretty weird) soundfont.
This tool is useful, but not foolproof!

If you have any questions or encounter any issues,  
please contact Mormegil#4775 or NoSloppy#4203 on the lightsaber discord server: discord.gg/lightsabers,  
or reach out to NoSloppy here on GitHub, on https://crucible.hubbe.net/, therebelarmory.com,   
a.k.a. Brian Conner on Facebook Open Source Sabers/Proffieboard Support groups.

Enjoy! I hope this is helpful.... and if you poke around, maybe learn a thing or two from it.
 (⌐■_■)
