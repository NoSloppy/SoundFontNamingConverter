z#!/bin/sh
	shopt -s extglob
	IFS=$'\n'

	echo " "
	echo "***********************************************************************"
	echo " Hello Saberfans! Welcome to the Soundfont Naming Converter v2.7"
	echo " - by @Mormegil and @NoSloppy - 2022"
	echo "***********************************************************************"
	echo " "
	echo " ** Please keep in mind, there's no reason to convert TO Proffie naming,"
	echo " ** because ProffieOS already supports other boards' fonts as they are."
	echo " "
	echo "To rename a Proffie soundfont for ideal performance,   enter 'PtoP'"
	echo " "
	echo "To convert a soundfont from CFX to Proffie,            enter 'CtoP'"
	echo "To convert a soundfont from CFX to GoldenHarvest,      enter 'CtoG'"
	echo "To convert a soundfont from CFX to Xenopixel,          enter 'CtoX'"
#	echo "To convert a soundfont from CFX to Asteria,            enter 'CtoA'"
	echo " "
	echo "To convert a soundfont from Proffie to CFX,            enter 'PtoC'"
	echo "To convert a soundfont from Proffie to GoldenHarvest,  enter 'PtoG'"
	echo "To convert a soundfont from Proffie to Xenopixel,      enter 'PtoX'"
#	echo "To convert a soundfont from Proffie to Asteria,        enter 'PtoA'"
	echo " "
	echo "To convert a soundfont from Xenopixel to CFX,          enter 'XtoC'"
	echo "To convert a soundfont from Xenopixel to GoldenHarvest,enter 'XtoG'"
	echo "To convert a soundfont from Xenopixel to Proffie,      enter 'XtoP'"
#	echo "To convert a soundfont from Xenopixel to Asteria,      enter 'XtoA'"
#	echo " "
#	echo "To convert a soundfont from GoldenHarvest to Proffie,  enter 'GtoP'"
#	echo "To convert a soundfont from GoldenHarvest to CFX,      enter 'GtoC'"
#	echo "To convert a soundfont from GoldenHarvest to Xenopixel,enter 'GtoX'"
#	echo "To convert a soundfont from GoldenHarvest to Asteria,  enter 'GtoA'"
#	echo " "
#	echo "To convert a soundfont from Asteria to Proffie,        enter 'AtoP'"
#	echo "To convert a soundfont from Asteria to CFX,            enter 'AtoC'"
#	echo "To convert a soundfont from Asteria to GoldenHarvest,  enter 'AtoG'"
#	echo "To convert a soundfont from Asteria to Xenopixel,      enter 'AtoX'"
	echo " "

	read boardchoice
#-------------------------------------------------------------------------------------------------------------------------------------

if [ "$boardchoice" = "PtoP" ]; then
	echo " "
	echo "You chose Proffie to Proper Proffie Soundfont renaming/organization."
	echo " "
	echo "Do you wish to rename a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to rename a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing renaming"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to rename several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing renaming"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed renaming progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report may produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi

	for font in ${dirs[@]}; do
			
		sounds=$(find "$font" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find -s "$font" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in ${font}".

		targetpath="Converted_to_Proper_Proffie"
		mkdir -p "${targetpath}/${font}"

		if [[ ! " ${otherfiles[*]} " =~ ${font}'/config.ini' ]]; then
    		echo "Adding missing config.ini"
    		rsync -Ab --no-perms "./inis/config.ini" "${targetpath}/${font}"
    	fi
		if [[ ! " ${otherfiles[*]} " =~ ${font}'/smoothsw.ini' ]]; then
    		echo "Adding missing smoothsw.ini"
    		rsync -Ab --no-perms "./inis/smoothsw.ini" "${targetpath}/${font}"
    	fi

		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "${targetpath}/${font}/extras"
			echo "Moving all extras to -> extras folder"
			rsync -rAb --no-perms "${font}/extras/" "${targetpath}/${font}/extras"
		fi

		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "${targetpath}/${font}/tracks"
			echo "Moving all tracks to -> tracks folder"
			rsync -rAb --no-perms "${font}/tracks/" "${targetpath}/${font}/tracks"
		fi

		for o in ${otherfiles}; do
			echo "Moving "${o}" to -> "${targetpath}/${font}
			rsync -Ab --no-perms "${o}" "${targetpath}/${font}"
		done

		counter=1
		extracounter=1
		hiddencounter=1
		trackcounter=1
		oldeffect="old"

		for src in ${sounds[@]}; do
			# Move extras folder as-is.
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi
			# Strip digits, path, and extension from filename
			effectfile="${src//[0-9]/}"
			effect="${effectfile##*/}"
			effect="${effect%.*}"
			# Reset counter for new effect type
			if [[ "$effect" != "$oldeffect" ]]; then
				counter=1
			fi			
			# Make subfolder for multiples, or leave single in root
			if [ $counter = 2 ]; then
				mkdir -p "${targetpath}/${font}/${effect}"
				# ${}target} is still 01 from previous loop
				rsync -Ab --no-perms --remove-source-files "${target}" "./${targetpath}/${font}/${effect}/${targetfile}"
				echo "Moving ${targetfile} into ${font}/${effect} subfolder"
			fi
			# Check if leading zero is needed
			if [ "${#effect}" -gt 6 ] || [ "$counter" -gt 9 ]; then 
				targetfile=$(printf %q "${effect}$counter.wav")	
			else
				targetfile=$(printf %q "${effect}0$counter.wav")
			fi
			# Set path for single or multiple sounds
			if [ $counter -ge 2 ]; then
				target="./${targetpath}/${font}/${effect}/${targetfile}"
			else
				target="./${targetpath}/${font}/${targetfile}"
			fi
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -Ab --no-perms  "${src}" "${target}"
			# increment counter for next effect sound
			counter=$((counter+1))
			oldeffect="${effect}"
		done

		echo " "
		echo "Converted soundfont saved in "${targetpath}
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------
elif [ "$boardchoice" = "CtoP" ]; then
	echo "You chose CFX to Proffie Soundfont renaming converter."
	echo " ** Please Note ** This should only be used on Plecter fonts that are POLYPHONIC."
	echo " Naming a monophonic font to Proffie convention will cause the sounds to not mix correctly and it'll sound weird/abrubt"
	echo " with no crossfades."
	echo " "
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi

	for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_Proffie/${dir}"
		mkdir -p "$targetpath"

    	echo "Adding missing config.ini"
    	rsync -Ab --no-perms "./inis/config.ini" "$targetpath"
    	echo "Adding missing smoothsw.ini"
    	rsync -Ab --no-perms "./inis/smoothsw.ini" "$targetpath"

    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack*/ "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		blastercounter=1
		bootcounter=1
		clashcounter=1
		colorcounter=1
		dragcounter=1
		enddragcounter=1
		endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		hswingcounter=1
		humcounter=1
		lockupcounter=1
		lswingcounter=1
		poweroffcounter=1
		poweroncounter=1
		preoncounter=1
		pstoffcounter=1
		slashcounter=1
		spincounter=1
		stabcounter=1
		startdragcounter=1
		startlockcounter=1
		swingcounter=1
		trackcounter=1
		
		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

				*laster*([0-9]).wav)
					if [ $blastercounter = 2 ]; then
						mkdir -p "$targetpath/blst"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/blst/$targetfile"
						echo "Moving $targetfile into ${dir}/blst subfolder"
					fi
					if [ "$blastercounter" -lt 10 ]; then 
						targetfile=$(printf %q "blst0$blastercounter.wav")	
					else
						targetfile=$(printf %q "blst$blastercounter.wav")
					fi
					if [ $blastercounter -ge 2 ]; then
						target="./$targetpath/blst/$targetfile"
					else
						target="$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					blastercounter=$((blastercounter+1))
				;;

				*oot*([0-9]).wav)
					if [ $bootcounter = 2 ]; then
						mkdir -p "$targetpath/boot"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/boot/$targetfile"
						echo "Moving $targetfile into ${dir}/boot subfolder"
					fi
					if [ "$bootcounter" -lt 10 ]; then 
						targetfile=$(printf %q "boot0$bootcounter.wav")	
					else
						targetfile=$(printf %q "boot$bootcounter.wav")
					fi
					if [ $bootcounter -ge 2 ]; then
						target="./$targetpath/boot/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					bootcounter=$((bootcounter+1))
				;;

				*clash*([0-9]).wav)
					if [ $clashcounter = 2 ]; then
						mkdir -p "$targetpath/clsh"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/clsh/$targetfile"
						echo "Moving $targetfile into ${dir}/clsh subfolder"
					fi
					if [ "$clashcounter" -lt 10 ]; then
						targetfile=$(printf %q "clsh0$clashcounter.wav")	
					else
						targetfile=$(printf %q "clsh$clashcounter.wav")
					fi
					if [ $clashcounter -ge 2 ]; then
						target="./$targetpath/clsh/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					clashcounter=$((clashcounter+1))
				;;
				
				*olor*([0-9]).wav)
					if [ $colorcounter = 2 ]; then
						mkdir -p "$targetpath/ccchange"
						# $target is still file#1 at this point
						echo "Moving $targetfile into ${dir}/ccchange subfolder and renaming to 0001.wav"
					fi
					if [ "$colorcounter" = 1 ]; then
						targetfile=$(printf %q "ccchange.wav")
					elif [ "$colorcounter" -lt 10 ]; then
						targetfile=$(printf %q "000$colorcounter.wav")	
					else
						targetfile=$(printf %q "00$colorcounter.wav")
					fi
					if [ $colorcounter -ge 2 ]; then
						target="./$targetpath/ccchange/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					colorcounter=$((colorcounter+1))
				;;
				
				drag*([0-9]).wav)
					if [ $dragcounter = 2 ]; then
						mkdir -p "$targetpath/drag"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/drag/$targetfile"
						echo "Moving $targetfile into ${dir}/drag subfolder"
					fi
					if [ "$dragcounter" -lt 10 ]; then
						targetfile=$(printf %q "drag0$dragcounter.wav")	
					else
						targetfile=$(printf %q "drag$dragcounter.wav")
					fi
					if [ $dragcounter -ge 2 ]; then
						target="./$targetpath/drag/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					dragcounter=$((dragcounter+1))
				;;

				*nddrag*([0-9]).wav)
					if [ $enddragcounter = 2 ]; then
						mkdir -p "$targetpath/enddrag"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/enddrag/$targetfile"
						echo "Moving $targetfile into ${dir}/enddrag subfolder"
					fi
						targetfile=$(printf %q "enddrag$enddragcounter.wav")
					if [ $enddragcounter -ge 2 ]; then
						target="./$targetpath/enddrag/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					enddragcounter=$((enddragcounter+1))
				;;

				*ndlock*([0-9]).wav)
					if [ $endlockcounter = 2 ]; then
						mkdir -p "$targetpath/endlock"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/endlock/$targetfile"
						echo "Moving $targetfile into ${dir}/endlock subfolder"
					fi
						targetfile=$(printf %q "endlock$endlockcounter.wav")
					if [ $endlockcounter -ge 2 ]; then
						target="./$targetpath/endlock/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					endlockcounter=$((endlockcounter+1))
				;;

				*ont*([0-9]).wav)
					if [ $fontcounter = 2 ]; then
						mkdir -p "$targetpath/font"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/font/$targetfile"
						echo "Moving $targetfile into ${dir}/font subfolder"
					fi
					if [ "$fontcounter" -lt 10 ]; then
						targetfile=$(printf %q "font0$fontcounter.wav")	
					else
						targetfile=$(printf %q "font$fontcounter.wav")
					fi
					if [ $fontcounter -ge 2 ]; then
						target="./$targetpath/font/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					fontcounter=$((fontcounter+1))
				;;
				
				*orce*|combo*([0-9]).wav)
					if [ $forcecounter = 2 ]; then
						mkdir -p "$targetpath/force"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/force/$targetfile"
						echo "Moving $targetfile into ${dir}/force subfolder"
					fi
					if [ "$forcecounter" -lt 10 ]; then
						targetfile=$(printf %q "force0$forcecounter.wav")	
					else
						targetfile=$(printf %q "force$forcecounter.wav")
					fi
					if [ $forcecounter -ge 2 ]; then
						target="./$targetpath/force/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					forcecounter=$((forcecounter+1))
				;;
				
				hswing*([0-9]).wav)
					if [ $hswingcounter = 2 ]; then
						mkdir -p "$targetpath/swingh"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/swingh/$targetfile"
						echo "Moving $targetfile into ${dir}/swingh subfolder"
					fi
					if [ "$hswingcounter" -lt 10 ]; then
						targetfile=$(printf %q "swingh0$hswingcounter.wav")	
					else
						targetfile=$(printf %q "swingh$hswingcounter.wav")
					fi
					if [ $hswingcounter -ge 2 ]; then
						target="./$targetpath/swingh/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					hswingcounter=$((hswingcounter+1))
				;;

				*um**([0-9]).wav)
					if [ $humcounter = 2 ]; then
						mkdir -p "$targetpath/hum"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/hum/$targetfile"
						echo "Moving $targetfile into ${dir}/hum subfolder"
					fi
					if [ "$humcounter" -lt 10 ]; then
						targetfile=$(printf %q "hum0$humcounter.wav")	
					else
						targetfile=$(printf %q "hum$humcounter.wav")
					fi
					if [ $humcounter -ge 2 ]; then
						target="./$targetpath/hum/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					humcounter=$((humcounter+1))
				;;	

				lswing*([0-9]).wav)
					if [ $lswingcounter = 2 ]; then
						mkdir -p "$targetpath/swingl"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/swingl/$targetfile"
						echo "Moving $targetfile into ${dir}/swingl subfolder"
					fi
					if [ "$lswingcounter" -lt 10 ]; then
						targetfile=$(printf %q "swingl0$lswingcounter.wav")	
					else
						targetfile=$(printf %q "swingl$lswingcounter.wav")
					fi
					if [ $lswingcounter -ge 2 ]; then
						target="./$targetpath/swingl/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					lswingcounter=$((lswingcounter+1))
				;;

				lock**([0-9]).wav)
					if [ $lockupcounter = 2 ]; then
						mkdir -p "$targetpath/lock"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/lock/$targetfile"
						echo "Moving $targetfile into ${dir}/lock subfolder"
					fi
					if [ "$lockupcounter" -lt 10 ]; then
						targetfile=$(printf %q "lock0$lockupcounter.wav")	
					else
						targetfile=$(printf %q "lock$lockupcounter.wav")
					fi
					if [ $lockupcounter -ge 2 ]; then
						target="./$targetpath/lock/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					lockupcounter=$((lockupcounter+1))
				;;

				*oweroff*|*wroff*([0-9]).wav)
					if [ $poweroffcounter = 2 ]; then
						mkdir -p "$targetpath/in"
						echo "making ${dir}/in subfolder"
						if [[ $target != *"in"* ]]; then
						rsync -Ab --no-perms --remove-source-files "./$targetpath/in01.wav" "./$targetpath/in/in01.wav"
						echo "Moving in01.wav into ${dir}/in subfolder"
						fi
					fi
					if [ "$poweroffcounter" -lt 10 ]; then
						targetfile=$(printf %q "in0$poweroffcounter.wav")	
					else
						targetfile=$(printf %q "in$poweroffcounter.wav")
					fi
					if [ $poweroffcounter -ge 2 ]; then
						target="./$targetpath/in/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					poweroffcounter=$((poweroffcounter+1))
				;;

				*oweron**([0-9]).wav)
					if [ $poweroncounter = 2 ]; then
						mkdir -p "$targetpath/out"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/out/$targetfile"
						echo "Moving $targetfile into ${dir}/out subfolder"
					fi
					if [ "$poweroncounter" -lt 10 ]; then
						targetfile=$(printf %q "out0$poweroncounter.wav")	
					else
						targetfile=$(printf %q "out$poweroncounter.wav")
					fi
					if [ $poweroncounter -ge 2 ]; then
						target="./$targetpath/out/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					poweroncounter=$((poweroncounter+1))
				;;

				*reon*([0-9]).wav)
					if [ $preoncounter = 2 ]; then
						mkdir -p "$targetpath/preon"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/preon/$targetfile"
						echo "Moving $targetfile into ${dir}/preon subfolder"
					fi
					if [ "$preoncounter" -lt 10 ]; then
						targetfile=$(printf %q "preon0$preoncounter.wav")	
					else
						targetfile=$(printf %q "preon$preoncounter.wav")
					fi
					if [ $preoncounter -ge 2 ]; then
						target="./$targetpath/preon/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					preoncounter=$((preoncounter+1))
				;;

				*stoff*([0-9]).wav)
					if [ $pstoffcounter = 2 ]; then
						mkdir -p "$targetpath/pstoff"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/pstoff/$targetfile"
						echo "Moving $targetfile into ${dir}/pstoff subfolder"
					fi
					if [ "$pstoffcounter" -lt 10 ]; then
						targetfile=$(printf %q "pstoff0$pstoffcounter.wav")	
					else
						targetfile=$(printf %q "pstoff$pstoffcounter.wav")
					fi
					if [ $pstoffcounter -ge 2 ]; then
						target="./$targetpath/pstoff/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					pstoffcounter=$((pstoffcounter+1))
				;;

				slash*([0-9]).wav)
					if [ $slashcounter = 2 ]; then
						mkdir -p "$targetpath/slsh"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/slsh/$targetfile"
						echo "Moving $targetfile into ${dir}/slsh subfolder"
					fi
					if [ "$slashcounter" -lt 10 ]; then
						targetfile=$(printf %q "slsh0$slashcounter.wav")	
					else
						targetfile=$(printf %q "slsh$slashcounter.wav")
					fi
					if [ $slashcounter -ge 2 ]; then
						target="./$targetpath/slsh/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					slashcounter=$((slashcounter+1))
				;;

				*pin*([0-9]).wav)
					if [ $spincounter = 2 ]; then
						mkdir -p "$targetpath/spin"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/spin/$targetfile"
						echo "Moving $targetfile into ${dir}/spin subfolder"
					fi
					if [ "$spincounter" -lt 10 ]; then
						targetfile=$(printf %q "spin0$spincounter.wav")	
					else
						targetfile=$(printf %q "spin$spincounter.wav")
					fi
					if [ $spincounter -ge 2 ]; then
						target="./$targetpath/spin/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					spincounter=$((spincounter+1))
				;;

				*tab*([0-9]).wav)
					if [ $stabcounter = 2 ]; then
						mkdir -p "$targetpath/stab"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/stab/$targetfile"
						echo "Moving $targetfile into ${dir}/stab subfolder"
					fi
					if [ "$stabcounter" -lt 10 ]; then
						targetfile=$(printf %q "stab0$stabcounter.wav")	
					else
						targetfile=$(printf %q "stab$stabcounter.wav")
					fi
					if [ $stabcounter -ge 2 ]; then
						target="./$targetpath/stab/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					stabcounter=$((stabcounter+1))
				;;

				*tartdrag*([0-9]).wav)
					if [ $startdragcounter = 2 ]; then
						mkdir -p "$targetpath/bgndrag"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/bgndrag/$targetfile"
						echo "Moving $targetfile into ${dir}/bgndrag subfolder"
					fi
						targetfile=$(printf %q "bgndrag$startdragcounter.wav")

					if [ $startdragcounter -ge 2 ]; then
						target="./$targetpath/bgndrag/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					startdragcounter=$((startdragcounter+1))
				;;

				*tartlock*([0-9]).wav)
					if [ $startlockcounter = 2 ]; then
						mkdir -p "$targetpath/bgnlock"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/bgnlock/$targetfile"
						echo "Moving $targetfile into ${dir}/bgnlock subfolder"
					fi
						targetfile=$(printf %q "bgnlock$startlockcounter.wav")

					if [ $startlockcounter -ge 2 ]; then
						target="./$targetpath/bgnlock/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					startlockcounter=$((startlockcounter+1))
				;;

				*wing*([0-9]).wav)
					if [ $swingcounter = 2 ]; then
						mkdir -p "$targetpath/swng"
						rsync -Ab --no-perms --remove-source-files "$target" "./$targetpath/swng/$targetfile"
						echo "Moving $targetfile into ${dir}/swng subfolder"
					fi
					if [ "$swingcounter" -lt 10 ]; then
						targetfile=$(printf %q "swng0$swingcounter.wav")	
					else
						targetfile=$(printf %q "swng$swingcounter.wav")
					fi
					if [ $swingcounter -ge 2 ]; then
						target="./$targetpath/swng/$targetfile"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
					swingcounter=$((swingcounter+1))
				;;

				*)
					echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done
		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
done

	echo "Soundfont conversion complete. If you see files with a '~' at the end, this file already existed in the output folder"
	echo "before the conversion and was renamed to avoid accidental overwriting."
	echo " "
#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "CtoG" ]; then
	echo " "
	echo "You chose CFX to GoldenHarvest Soundfont converter."
	echo "*NOTE* Single font file supported."
	echo "- If you have multiple font.wavs in the source font, the last one will be used"
	echo "- save.wav not generated."
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi


for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_GoldenHarvest/${dir}"
		mkdir -p "$targetpath"

    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack*/ "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		startdragcounter=1
		startlockcounter=1
		blastercounter=1
		bootcounter=1
		colorcounter=1
		clashcounter=1
		dragcounter=1
		enddragcounter=1
		endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		hswingcounter=1
		humMcounter=1
		lockupcounter=1
		lswingcounter=1
		preoncounter=1
		pstoffcounter=1
		poweroffcounter=1
		poweroncounter=1
		# savecounter=1
		slashcounter=1
		spincounter=1
		stabcounter=1
		swingcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

				*laster*([0-9]).wav)
					targetfile=$(printf %q "blast$blastercounter.wav")
					blastercounter=$((blastercounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target" 
				;;
				
				*oot*([0-9]).wav)
					targetfile=$(printf %q "boot$bootcounter.wav")
					bootcounter=$((bootcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target" 
				;;
				
				*olor*([0-9]).wav)
					targetfile=$(printf %q "change$colorcounter.wav")
					colorcounter=$((colorcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*clash*([0-9]).wav)
					targetfile=$(printf %q "clash$clashcounter.wav")
					clashcounter=$((clashcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				drag*([0-9]).wav)
					targetfile=$(printf %q "drag$dragcounter.wav")
					dragcounter=$((dragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*nddrag*([0-9]).wav)
					targetfile=$(printf %q "enddrag$enddragcounter.wav")
					enddragcounter=$((enddragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*ndlock*([0-9]).wav)
					targetfile=$(printf %q "endlock$endlockcounter.wav")
					endlockcounter=$((endlockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*ont**([0-9]).wav)
					targetfile=$(printf %q "font.wav")
					target="./$targetpath/$targetfile"
					if [[ $fontcounter = 1 ]]; then
						if [ "$verbosity" = "1" ]; then
							echo "Converting ${src} to ${target}"
						fi
						rsync -Ab --no-perms "${src}" "${target}"
					fi
					if [[ $fontcounter = 2 ]]; then
						echo "-------- More than one font.wav in source, using the first one."
					fi
					fontcounter=$((fontcounter+1))
				;;

				*orce*|quote*([0-9]).wav)
					targetfile=$(printf %q "force$forcecounter.wav")
					forcecounter=$((forcecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				hswing*([0-9]).wav)
					targetfile=$(printf %q "hswing$hswingcounter.wav")
					hswingcounter=$((hswingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*um**([0-9]).wav)
					targetfile=$(printf %q "hum$humMcounter.wav")
					humMcounter=$((humMcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;
				
				lock**([0-9]).wav)
					targetfile=$(printf %q "lock$lockupcounter.wav")
					lockupcounter=$((lockupcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				lswing*([0-9]).wav)
					targetfile=$(printf %q "lswing$lswingcounter.wav")
					lswingcounter=$((lswingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*reon*([0-9]).wav)
					targetfile=$(printf %q "preon$preoncounter.wav")
					preoncounter=$((preoncounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

		    	*stoff**([0-9]).wav)
					targetfile=$(printf %q "pstoff$pstoffcounter.wav")
					pstoffcounter=$((pstoffcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target" 
				;;

				*oweroff*|*wroff*([0-9]).wav)
					targetfile=$(printf %q "pwroff$poweroffcounter.wav")
					poweroffcounter=$((poweroffcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;
				
				*oweron**([0-9]).wav)
					targetfile=$(printf %q "pwron$poweroncounter.wav")
					poweroncounter=$((poweroncounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

	# save sounds are currently only supported by GoldenHarvest and therefore ignored
	# since the source has nothing to provide. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 			save*([0-9]).wav)
	# 				targetfile=$(printf %q "save$savecounter.wav")
	# 				savecounter=$((savecounter+1))
	# 				target="./$targetpath/$targetfile"
	# 				if [ "$verbosity" = "1" ]; then
	# 					echo "Converting ${src} to $target"
	# 				fi
	# 				rsync -Ab --no-perms "${src}" "$target" 
	# 			;;

				slash*([0-9]).wav)
					targetfile=$(printf %q "slash$slashcounter.wav")
					slashcounter=$((slashcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*pin*([0-9]).wav)
					targetfile=$(printf %q "spin$spincounter.wav")
					spincounter=$((spincounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				*tab*([0-9]).wav)
					targetfile=$(printf %q "stab$stabcounter.wav")
					stabcounter=$((stabcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;


				*tartdrag*([0-9]).wav)
					targetfile=$(printf %q "bgndrag$startdragcounter.wav")
					startdragcounter=$((startdragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target" 
				;;

				*tartlock*([0-9]).wav)
					targetfile=$(printf %q "bgnlock$startlockcounter.wav")
					startlockcounter=$((startlockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target" 
				;;

				*wing*([0-9]).wav)
					targetfile=$(printf %q "swing$swingcounter.wav")
					swingcounter=$((swingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;
				
				*)
					echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done

		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "CtoX" ]; then
	echo " "
	echo "You chose CFX to Xenopixel Soundfont converter."
	echo " "
	echo "** NOTE ** "
	echo "boot sounds are converted to power on.wav and live in the 'set' folder."
	echo "--- If there are more than one converted, the last one will be the resulting file."
	echo " "
	echo "color sounds are currently not supported by Xenopixel and therefore ignored."
	echo "endlock sounds are currently not supported by Xenopixel and therefore ignored."
	echo "spin sounds are currently not supported by Xenopixel and therefore ignored."
	echo "stab sounds are currently not supported by Xenopixel and therefore ignored." 
	echo " "
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi

	for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_Xenopixel/${dir}"
		mkdir -p "$targetpath"
	    mkdir -p "$targetpath/set"

    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack*/ "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		blastercounter=1
		bootcounter=1
		clashcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		hswingcounter=1
		humcounter=1
		lswingcounter=1
		poweroffcounter=1
		poweroncounter=1
		lockcounter=1
		lockupcounter=1
		preoncounter=1
		slashcounter=1
		# spincounter=1
		# stabcounter=1
		swingcounter=1
		trackcounter=1


		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

			*laster*([0-9]).wav)
				targetfile="blaster ($blastercounter).wav"
				blastercounter=$((blastercounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}" 
			;;

	# boot sounds are converted to 'power on.wav' and live in the 'set' folder.
	# If there are more than one converted, the last one will be the resulting file.
			*oot*([0-9]).wav)
				targetfile="power on.wav"
				bootcounter=$((bootcounter+1))
				target="./$targetpath/set/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}" 
			;;

			*clash*([0-9]).wav)
				targetfile="clash ($clashcounter).wav"
				clashcounter=$((clashcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

	# color sounds are currently not supported by Xenopixel and therefore ignored.
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 	    *olor*([0-9]).wav)
	# 			targetfile="color ($colorcounter).wav"
	# 			colorcounter=$((colorcounter+1))
	# 			target="./$targetpath/$targetfile"
	# 			if [ "$verbosity" = "1" ]; then
	# 				echo "Converting ${src} to ${target}"
	# 			fi
	# 			rsync -Ab --no-perms "${src}" "${target}"
	# 		;;

			drag*([0-9]).wav)
				targetfile="drag ($dragcounter).wav"
				dragcounter=$((dragcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

	# endlock sounds are currently not supported by Xenopixel and therefore ignored.
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 	  	*ndlock*([0-9]).wav)
	# 			targetfile="endlock ($endlockcounter).wav"
	# 			endlockcounter=$((endlockcounter+1))
	# 			target="./$targetpath/$targetfile"
	# 			if [ "$verbosity" = "1" ]; then
	# 				echo "Converting ${src} to ${target}"
	# 			fi
	# 			rsync -Ab --no-perms "${src}" "${target}"
	# 		;;

			*ont*([0-9]).wav)
				targetfile="font ($fontcounter).wav"
				fontcounter=$((fontcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			*orce*|combo*([0-9]).wav)
				targetfile="force ($forcecounter).wav"
				forcecounter=$((forcecounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			*um**([0-9]).wav)
				targetfile="hum ($humcounter).wav"
				humcounter=$((humcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			*oweroff*|*wroff*([0-9]).wav)
				targetfile="in ($poweroffcounter).wav"
				poweroffcounter=$((poweroffcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			lock**([0-9]).wav)
				targetfile="lock ($lockcounter).wav"
				lockcounter=$((lockcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			*oweron**([0-9]).wav)
				targetfile="out ($poweroncounter).wav"
				poweroncounter=$((poweroncounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			hswing*([0-9]).wav)
				targetfile="hswing ($hswingcounter).wav"
				hswingcounter=$((hswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			lswing*([0-9]).wav)
				targetfile="lswing ($lswingcounter).wav"
				lswingcounter=$((lswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			*reon*([0-9]).wav)
				targetfile="preon ($preoncounter).wav"
				if [ "$preoncounter" -ge 5 ]; then
					preoncounter=1
				else
					preoncounter=$((preoncounter+1))
				fi
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;


			slash*([0-9]).wav)
				targetfile="slash ($slashcounter).wav"
				slashcounter=$((slashcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

	# spin sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 	  	*pin*([0-9]).wav)
	# 			targetfile="spin ($spincounter).wav"
	# 			spincounter=$((spincounter+1))
	# 			target="./$targetpath/$targetfile"
	# 			if [ "$verbosity" = "1" ]; then
	# 				echo "Converting ${src} to ${target}"
	# 			fi
	# 			rsync -Ab --no-perms "${src}" "${target}"
	# 		;;		

	# stab sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 	  	*tab*([0-9]).wav)
	# 			targetfile="stab ($stabcounter).wav"
	# 			stabcounter=$((stabcounter+1))
	# 			target="./$targetpath/$targetfile"
	# 			if [ "$verbosity" = "1" ]; then
	# 				echo "Converting ${src} to ${target}"
	# 			fi
	# 			rsync -Ab --no-perms "${src}" "${target}"
	# 		;;


		  	*wing*([0-9]).wav)
				targetfile="swing ($swingcounter).wav"
				swingcounter=$((swingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -Ab --no-perms "${src}" "${target}"
			;;

			*)
				echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done

		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "PtoC" ]; then
	echo " "
	echo "You chose Proffie to CFX Soundfont converter."
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi


for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_CFX/${dir}"
		mkdir -p "$targetpath"

    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack* "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		bgndragcounter=1
		bgnlockcounter=1
		blstcounter=1
		bootcounter=1
		clshcounter=1
		ccchangecounter=1
		dragcounter=1
		enddragcounter=1
		endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		outcounter=1
		preoncounter=1
		pstoffcounter=1
		slshcounter=1
		spincounter=1
		stabcounter=1
		swinghcounter=1
		swinglcounter=1
		swngcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

				bgndrag*([0-9]).wav)
					targetfile=$(printf %q "startdrag$bgndragcounter.wav")
					bgndragcounter=$((bgndragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

				bgnlock*([0-9]).wav)
					targetfile=$(printf %q "startlock$bgnlockcounter.wav")
					bgnlockcounter=$((bgnlockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

				blst*([0-9]).wav)
					if [ "$blstcounter" -eq 1 ]; then 
						targetfile=$(printf %q "blaster.wav")	
					else
						targetfile=$(printf %q "blaster$blstcounter.wav")
					fi
					blstcounter=$((blstcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;
				
				boot*([0-9]).wav)
					if [ "$bootcounter" -eq 1 ]; then 
						targetfile=$(printf %q "boot.wav")	
					else
						targetfile=$(printf %q "boot$bootcounter.wav")
					fi
					bootcounter=$((bootcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;
				
				clsh*([0-9]).wav)
					targetfile=$(printf %q "clash$clshcounter.wav")
					clshcounter=$((clshcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				ccchange*|color*([0-9]).wav)
					if [ "$ccchangecounter" -eq 1 ]; then 
						targetfile=$(printf %q "color.wav")	
					else
						targetfile=$(printf %q "color$ccchangecounter.wav")
					fi
					ccchangecounter=$((ccchangecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				drag*([0-9]).wav)
					if [ "$dragcounter" -eq 1 ]; then 
						targetfile=$(printf %q "drag.wav")	
					else
						targetfile=$(printf %q "drag$dragcounter.wav")
					fi
					dragcounter=$((dragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				enddrag*([0-9]).wav)
					targetfile=$(printf %q "enddrag$enddragcounter.wav")
					enddragcounter=$((enddragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				endlock*([0-9]).wav)
					targetfile=$(printf %q "endlock$endlockcounter.wav")
					endlockcounter=$((endlockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				font*([0-9]).wav)
					if [ "$fontcounter" -eq 1 ]; then 
						targetfile=$(printf %q "font.wav")	
					else
						targetfile=$(printf %q "font$fontcounter.wav")
					fi
					fontcounter=$((fontcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				force*|quote*([0-9]).wav)
					if [ "$forcecounter" -eq 1 ]; then 
						targetfile=$(printf %q "force.wav")	
					else
						targetfile=$(printf %q "force$forcecounter.wav")
					fi
					forcecounter=$((forcecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				hum*([0-9]).wav)
					targetfile=$(printf %q "humM$humcounter.wav")
					humcounter=$((humcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				in*([0-9]).wav)
					if [ "$incounter" -eq 1 ]; then 
						targetfile=$(printf %q "poweroff.wav")	
					elif [ "$incounter" -eq 2 ]; then 
						targetfile=$(printf %q "pwroff$incounter.wav")
					elif [ "$incounter" -ge 3 ]; then
						targetfile=$(printf %q "poweroff$((incounter-1)).wav")
					fi
					incounter=$((incounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				lock*([0-9]).wav)
					if [ "$lockcounter" -eq 1 ]; then 
						targetfile=$(printf %q "lockup.wav")	
					else
						targetfile=$(printf %q "lockup$lockcounter.wav")
					fi
					lockcounter=$((lockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				out*([0-9]).wav)
					if [ "$outcounter" -eq 1 ]; then 
						targetfile=$(printf %q "poweron.wav")	
					else
						targetfile=$(printf %q "poweron$outcounter.wav")
					fi
					outcounter=$((outcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				preon*([0-9]).wav)
					targetfile=$(printf %q "preon$preoncounter.wav")
					preoncounter=$((preoncounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				pstoff*([0-9]).wav)
					targetfile=$(printf %q "pstoff$pstoffcounter.wav")
					pstoffcounter=$((pstoffcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				spin*([0-9]).wav)
					targetfile=$(printf %q "spin$spincounter.wav")
					spincounter=$((spincounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				stab*([0-9]).wav)
					targetfile=$(printf %q "stab$stabcounter.wav")
					stabcounter=$((stabcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				swingh*([0-9]).wav)
					targetfile=$(printf %q "hswing$swinghcounter.wav")
					swinghcounter=$((swinghcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				swingl*([0-9]).wav)
					targetfile=$(printf %q "lswing$swinglcounter.wav")
					swinglcounter=$((swinglcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				slsh*([0-9]).wav)
					targetfile=$(printf %q "slash$slshcounter.wav")
					slshcounter=$((slshcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				swng*([0-9]).wav)
					targetfile=$(printf %q "swing$swngcounter.wav")
					swngcounter=$((swngcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				*)
				echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done

		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "PtoG" ]; then
	echo " "
	echo "You chose Proffie to GoldenHarvest Soundfont converter."
	echo "*NOTE* Single font file supported."
	echo "- If you have multiple font.wavs in the source font, the first one will be used"
	echo " "
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi


for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_GoldenHarvest/${dir}"
		mkdir -p "$targetpath"

    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack* "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		bgndragcounter=1
		bgnlockcounter=1
		blstcounter=1
		bootcounter=1
		clshcounter=1
		ccchangecounter=1
		dragcounter=1
		enddragcounter=1
		endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		outcounter=1
		preoncounter=1
		slshcounter=1
		spincounter=1
		stabcounter=1
		swinghcounter=1
		swinglcounter=1
		swngcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

				bgndrag*([0-9]).wav)
					targetfile=$(printf %q "bgndrag$bgndragcounter.wav")
					bgndragcounter=$((bgndragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

				bgnlock*([0-9]).wav)
					targetfile=$(printf %q "bgnlock$bgnlockcounter.wav")
					bgnlockcounter=$((bgnlockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

				blst*([0-9]).wav)
					targetfile=$(printf %q "blast$blstcounter.wav")
					blstcounter=$((blstcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;
				
				boot*([0-9]).wav)
					targetfile=$(printf %q "boot$bootcounter.wav")
					bootcounter=$((bootcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;
				
				clsh*([0-9]).wav)
					targetfile=$(printf %q "clash$clshcounter.wav")
					clshcounter=$((clshcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				ccchange*|color*([0-9]).wav)
					targetfile=$(printf %q "change$ccchangecounter.wav")
					ccchangecounter=$((ccchangecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				drag*([0-9]).wav)
					targetfile=$(printf %q "drag$dragcounter.wav")
					dragcounter=$((dragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				enddrag*([0-9]).wav)
					targetfile=$(printf %q "enddrag$enddragcounter.wav")
					enddragcounter=$((enddragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				endlock*([0-9]).wav)
					targetfile=$(printf %q "endlock$endlockcounter.wav")
					endlockcounter=$((endlockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				font**([0-9]).wav)
					targetfile=$(printf %q "font.wav")
					target="./$targetpath/$targetfile"
					if [[ $fontcounter = 1 ]]; then
						if [ "$verbosity" = "1" ]; then
							echo "Converting ${src} to ${target}"
						fi
						rsync -Ab --no-perms "${src}" "${target}"
					fi
					if [[ $fontcounter = 2 ]]; then
						echo "-------- More than one font.wav in source, using the first one."
					fi
					fontcounter=$((fontcounter+1))
				;;
				
				force*|quote*([0-9]).wav)
					targetfile=$(printf %q "force$forcecounter.wav")
					forcecounter=$((forcecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				hum*([0-9]).wav)
					targetfile=$(printf %q "hum$humcounter.wav")
					humcounter=$((humcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				in*([0-9]).wav)
					targetfile=$(printf %q "pwroff$incounter.wav")
					incounter=$((incounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				lock*([0-9]).wav)
					targetfile=$(printf %q "lock$lockcounter.wav")
					lockcounter=$((lockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				out*([0-9]).wav)
					targetfile=$(printf %q "pwron$outcounter.wav")
					outcounter=$((outcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				preon*([0-9]).wav)
					targetfile=$(printf %q "preon$preoncounter.wav")
					preoncounter=$((preoncounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;


		    	pstoff**([0-9]).wav)
					targetfile=$(printf %q "pstoff$pstoffcounter.wav")
					pstoffcounter=$((pstoffcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

				slsh**([0-9]).wav)
					targetfile=$(printf %q "slash$slshcounter.wav")
					slshcounter=$((slshcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to $target"
					fi
					rsync -Ab --no-perms "${src}" "$target"
				;;

				spin*([0-9]).wav)
					targetfile=$(printf %q "spin$spincounter.wav")
					spincounter=$((spincounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				stab*([0-9]).wav)
					targetfile=$(printf %q "stab$stabcounter.wav")
					stabcounter=$((stabcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				swingh*([0-9]).wav)
					targetfile=$(printf %q "hswing$swinghcounter.wav")
					swinghcounter=$((swinghcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				swingl*([0-9]).wav)
					targetfile=$(printf %q "lswing$swinglcounter.wav")
					swinglcounter=$((swinglcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				swng*|slsh*([0-9]).wav)
					targetfile=$(printf %q "swing$swngcounter.wav")
					swngcounter=$((swngcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				*)
				echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done

		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "PtoX" ]; then
	echo " "
	echo "You chose Proffie to Xenopixel Soundfont converter."
	echo " "
	echo "** NOTE ** "
	echo "boot sounds are converted to power on.wav and live in the 'set' folder."
	echo "--- If there are more than one converted, the last one will be the resulting file."
	echo " "
	echo "color sounds are currently not supported by Xenopixel and therefore ignored."
	echo "endlock sounds are currently not supported by Xenopixel and therefore ignored."
	echo "spin sounds are currently not supported by Xenopixel and therefore ignored."
	echo "stab sounds are currently not supported by Xenopixel and therefore ignored." 
	echo " "
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi


	for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_Xenopixel/${dir}"
		mkdir -p "$targetpath"
	    mkdir -p "$targetpath/set"
	    mkdir -p "$targetpath/tracks"

    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack* "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		blstcounter=1
		bootcounter=1
		clshcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		outcounter=1
		preoncounter=1
		swinghcounter=1
		swinglcounter=1
		# spincounter=1
		# stabcounter=1
		swngcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in
				blst*([0-9]).wav)
					targetfile="blaster ($blstcounter).wav"
					blstcounter=$((blstcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;
					
		# boot sounds are converted to 'power on.wav and live in the 'set' folder.
		# If there are more than one converted, the last one will be the resulting file.
				boot*([0-9]).wav)
					targetfile="power on.wav"
					bootcounter=$((bootcounter+1))
					target="./$targetpath/set/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;
				
				clsh*([0-9]).wav)
					targetfile="clash ($clshcounter).wav"
					clshcounter=$((clshcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
			 # color sounds are currently not supported by Xenopixel and therefore ignored. 
			 # Uncomment counter above and code here and adapt targetfile if needed later.			
			 # 	color*([0-9]).wav)
				#  	targetfile="color ($colorcounter).wav"
				#  	colorcounter=$((colorcounter+1))
				# 	target="./$targetpath/$targetfile"
				#  	if [ "$verbosity" = "1" ]; then
				#  		echo "Converting ${src} to ${target}"
				#  	fi
				#  	rsync -Ab --no-perms "${src}" "${target}"
			 # 	;;
				
				drag*([0-9]).wav)
					targetfile="drag ($dragcounter).wav"
					dragcounter=$((dragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
			# endlock sounds are currently not supported by Xenopixel and therefore ignored. 
			# Uncomment counter above and code here and adapt targetfile if needed later.	
			# 	endlock*([0-9]).wav)
			# 		targetfile="endlock ($endlockcounter).wav"
			# 		endlockcounter=$((endlockcounter+1))
			# 		target="./$targetpath/$targetfile"
			# 		if [ "$verbosity" = "1" ]; then
			# 			echo "Converting ${src} to ${target}"
			# 		fi
			# 		rsync -Ab --no-perms "${src}" "${target}"
			#  	;;
				
				font*([0-9]).wav)
					targetfile="font ($fontcounter).wav"
					fontcounter=$((fontcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				force*|quote*([0-9]).wav)
					targetfile="force ($forcecounter).wav"
					forcecounter=$((forcecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				hum*([0-9]).wav)
					targetfile="hum ($humcounter).wav"
					humcounter=$((humcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				in*([0-9]).wav)
					targetfile="in ($incounter).wav"
					incounter=$((incounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				lock*([0-9]).wav)
					targetfile="lock ($lockcounter).wav"
					lockcounter=$((lockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				out*([0-9]).wav)
					targetfile="out ($outcounter).wav"
					outcounter=$((outcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				swingh*([0-9]).wav)
					targetfile="swingh ($swinghcounter).wav"
					swinghcounter=$((swinghcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				swingl*([0-9]).wav)
					targetfile="swingl ($swinglcounter).wav"
					swinglcounter=$((swinglcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				preon*([0-9]).wav)
					targetfile="preon ($preoncounter).wav"
					if [ "$preoncounter" -ge 5 ]; then
						preoncounter=1
					else
						preoncounter=$((preoncounter+1))
					fi
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

		# spin sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		spin*([0-9]).wav)
		# 			targetfile="spin ($spincounter).wav"
		# 			spincounter=$((spincounter+1))
		# 			target="./$targetpath/$targetfile"
		# 			if [ "$verbosity" = "1" ]; then
		# 				echo "Converting ${src} to ${target}"
		# 			fi
		# 			rsync -Ab --no-perms "${src}" "${target}"
		# 		;;		

		# stab sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		stab*([0-9]).wav)
		# 			targetfile="stab ($stabcounter).wav"
		# 			stabcounter=$((stabcounter+1))
		# 			target="./$targetpath/$targetfile"
		# 			if [ "$verbosity" = "1" ]; then
		# 				echo "Converting ${src} to ${target}"
		# 			fi
		# 			rsync -Ab --no-perms "${src}" "${target}"
		# 		;;

				swng*|slsh*([0-9]).wav)
					targetfile="swing ($swngcounter).wav"
					swngcounter=$((swngcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;
				
				*)
					echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done

		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "XtoC" ]; then
	echo " "
	echo "You chose Xenopixel to CFX Soundfont converter."
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi

	for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_CFX/${dir}"
		mkdir -p "$targetpath"
	
    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack*/ "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		blastercounter=1
		bootcounter=1
		clashcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		hswingcounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		lswingcounter=1
		outcounter=1
		preoncounter=1
		# spincounter=1
		# stabcounter=1
		swingcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

				blaster**([0-9]).wav)
					if [ "$blastercounter" -eq 1 ]; then 
						targetfile=$(printf %q "blaster.wav")	
					else
						targetfile=$(printf %q "blaster$blastercounter.wav")
					fi
					blastercounter=$((blastercounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

		# boot sounds are 'power on' wav files on Xenopixel. 
				power***([0-9]).wav)
					targetfile=$(printf %q "boot$bootcounter.wav")
					bootcounter=$((bootcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

				*clash**([0-9]).wav)
					targetfile=$(printf %q "clash$clashcounter.wav")
					clashcounter=$((clashcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

		# color sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		color*([0-9]).wav)
		# 			targetfile=$(printf %q "color$colorcounter.wav")
		# 			colorcounter=$((colorcounter+1))
		# 			target="./$targetpath/$targetfile"
		# 			if [ "$verbosity" = "1" ]; then
		# 				echo "Converting ${src} to ${target}"
		# 			fi
		# 			rsync -Ab --no-perms "${src}" "${target}"
		# 		;;

				drag**([0-9]).wav)
					if [ "$dragcounter" -eq 1 ]; then 
						targetfile=$(printf %q "drag.wav")	
					else
						targetfile=$(printf %q "drag$dragcounter.wav")
					fi
					dragcounter=$((dragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

		# endlock sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.	
		# 		endlock*([0-9]).wav)
		# 			targetfile=$(printf %q "endlock$endlockcounter.wav")
		# 			endlockcounter=$((endlockcounter+1))
		# 			target="./$targetpath/$targetfile"
		# 			if [ "$verbosity" = "1" ]; then
		# 				echo "Converting ${src} to ${target}"
		# 			fi
		# 			rsync -Ab --no-perms "${src}" "${target}"
		# 		;;

				font**([0-9]).wav)
					if [ "$fontcounter" -eq 1 ]; then 
						targetfile=$(printf %q "font.wav")	
					else
						targetfile=$(printf %q "font$fontcounter.wav")
					fi
					fontcounter=$((fontcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				force**([0-9]).wav)
					if [ "$forcecounter" -eq 1 ]; then 
						targetfile=$(printf %q "force.wav")	
					else
						targetfile=$(printf %q "force$forcecounter.wav")
					fi
					forcecounter=$((forcecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				hswing**|swingh**([0-9]).wav)
					targetfile=$(printf %q "hswing$hswingcounter.wav")
					hswingcounter=$((hswingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				*um**([0-9]).wav)
					targetfile=$(printf %q "humM$humcounter.wav")
					humcounter=$((humcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				in**([0-9]).wav)
					if [ "$incounter" -eq 1 ]; then
						targetfile=$(printf %q "poweroff.wav")	
					elif [ "$incounter" -eq 2 ]; then 
						targetfile=$(printf %q "pwroff$incounter.wav")
					elif [ "$incounter" -ge 3 ]; then
						targetfile=$(printf %q "poweroff$((incounter-1)).wav")
					fi
					incounter=$((incounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				lock**([0-9]).wav)
					if [ "$lockcounter" -eq 1 ]; then 
						targetfile=$(printf %q "lockup.wav")	
					else
						targetfile=$(printf %q "lockup$lockcounter.wav")
					fi
					lockcounter=$((lockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				lswing**|swingl**([0-9]).wav)
					targetfile=$(printf %q "lswing$lswingcounter.wav")
					lswingcounter=$((lswingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				out**([0-9]).wav)
					if [ "$outcounter" -eq 1 ]; then 
						targetfile=$(printf %q "poweron.wav")	
					else
						targetfile=$(printf %q "poweron$outcounter.wav")
					fi
					outcounter=$((outcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				preon**([0-9]).wav)
					if [ "$preoncounter" -eq 1 ]; then 
						targetfile=$(printf %q "preon.wav")	
					else
						targetfile=$(printf %q "preon$preoncounter.wav")
					fi
					preoncounter=$((preoncounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				swing**([0-9]).wav)
					targetfile=$(printf %q "swing$swingcounter.wav")
					swingcounter=$((swingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					;;

				*)
					echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done

		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "XtoG" ]; then
	echo " "
	echo "You chose Xenopixel to GoldenHarvest Soundfont converter."
	echo "*NOTE* Single font file supported."
	echo "- If you have multiple font.wavs in the source font, the last one will be used"
	echo "- save.wav not generated."
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi

	for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_GoldenHarvest/${dir}"
		mkdir -p "$targetpath"
	
    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack* "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		blastercounter=1
		# bootcounter=1
		clashcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		hswingcounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		lswingcounter=1
		outcounter=1
		# preoncounter=1
		# spincounter=1
		# stabcounter=1
		# swingcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

				blaster**([0-9]).wav)
					targetfile=$(printf %q "blast$blastercounter.wav")
					blastercounter=$((blastercounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}" 
				;;

		# boot sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		boot**([0-9]).wav)
		# 			targetfile=$(printf %q "boot$bootcounter.wav")
		# 			bootcounter=$((bootcounter+1))
		# 			target="./$targetpath/$targetfile"
		# 			if [ "$verbosity" = "1" ]; then
		# 				echo "Converting ${src} to ${target}"
		# 			fi
		# 			rsync -Ab --no-perms "${src}" "${target}" 
		# 		;;

				*clash**([0-9]).wav)
					targetfile=$(printf %q "clash$clashcounter.wav")
					clashcounter=$((clashcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

		# color sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		color**([0-9]).wav)
		# 			targetfile=$(printf %q "color$colorcounter.wav")
		# 			colorcounter=$((colorcounter+1))
		# 			target="./$targetpath/$targetfile"
		# 			if [ "$verbosity" = "1" ]; then
		# 				echo "Converting ${src} to ${target}"
		# 			fi
		# 			rsync -Ab --no-perms "${src}" "${target}"
		# 		;;

				drag**([0-9]).wav)
					targetfile=$(printf %q "drag$dragcounter.wav")
					dragcounter=$((dragcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

		# endlock sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.	
		# 		endlock*([0-9]).wav)
		# 			targetfile=$(printf %q "endlock$endlockcounter.wav")
		# 			endlockcounter=$((endlockcounter+1))
		# 			target="./$targetpath/$targetfile"
		# 			if [ "$verbosity" = "1" ]; then
		# 				echo "Converting ${src} to ${target}"
		# 			fi
		# 			rsync -Ab --no-perms "${src}" "${target}"
		# 		;;

				font**([0-9]).wav)
					targetfile=$(printf %q "font.wav")
					target="./$targetpath/$targetfile"
					if [[ $fontcounter = 1 ]]; then
						if [ "$verbosity" = "1" ]; then
							echo "Converting ${src} to ${target}"
						fi
						rsync -Ab --no-perms "${src}" "${target}"
					fi
					if [[ $fontcounter = 2 ]]; then
						echo "-------- More than one font.wav in source, using the first one."
					fi
					fontcounter=$((fontcounter+1))
				;;

				force**([0-9]).wav)
					targetfile=$(printf %q "force$forcecounter.wav")
					forcecounter=$((forcecounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				*um**([0-9]).wav)
					targetfile=$(printf %q "hum$humcounter.wav")
					humcounter=$((humcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				hswing**|swingh**([0-9]).wav)
					targetfile=$(printf %q "hswing$hswingcounter.wav")
					hswingcounter=$((hswingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				in**([0-9]).wav)
					targetfile=$(printf %q "pwroff$incounter.wav")
					incounter=$((incounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				lock**([0-9]).wav)
					targetfile=$(printf %q "lockup$lockcounter.wav")
					lockcounter=$((lockcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				lswing**|swingl**([0-9]).wav)
					targetfile=$(printf %q "lswing$lswingcounter.wav")
					lswingcounter=$((lswingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				out**([0-9]).wav)
					targetfile=$(printf %q "pwron$outcounter.wav")
					outcounter=$((outcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				swing**([0-9]).wav)
					targetfile=$(printf %q "swing$swingcounter.wav")
					swingcounter=$((swingcounter+1))
					target="./$targetpath/$targetfile"
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
				;;

				*)
					echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done

		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

#-------------------------------------------------------------------------------------------------------------------------------------

elif [ "$boardchoice" = "XtoP" ]; then
	echo "You chose Xenopixel to Proffie Soundfont converter."
	echo "Do you wish to convert a single soundfont (enter '1') or a folder containing several soundfonts in subfolders (enter '2')?" 
	echo "If you choose 2, Make sure each sub-folder only contains one soundfont. Otherwise the soundfonts will get mixed!"

	read selection

	if [ "$selection" = "1" ]; then
		echo "You chose to convert a single soundfont. Please enter the name of the font folder containting the soundfont files."
		echo "You may need to enter the path if it's a subfolder of where you are (such as 'SoundfontMaker/Font')"
		
		read input
		dirs=$(find "$input" -maxdepth 0 -type d)
		
		echo "Found the following soundfont folder:"
		echo $dirs
		echo "Does this folder only contain one soundfont? (y/n)"
		
		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	elif [ "$selection" = "2" ]; then 
		echo "You chose to convert several soundfonts. Each soundfont must be in a single subfolder."
		echo "Please enter the name of the folder containing the soundfont folders."
		
		read input
		dirs=$(find "$input" -mindepth 1 -maxdepth 1 -type d)
		
		echo "Found the following directories for soundfonts:"
		echo $dirs
		echo "Does each of these folders only contain one soundfont? (y/n)"

		read input2

		if [[ "$input2" = "y" || "$input2" = "Y" ]]; then
			echo "Continuing conversion"
		else
			echo "Aborting program"
			exit
		fi
		
	else
		echo "Your selection is invalid. Aborting program"
		exit
	fi

	echo "Do you wish a detailed conversion progess report ('1') or only the imporant steps ('2')?"
	echo "Warning, the detailed report will produce a lot of console output!"

	read verbosity

	if [ "$verbosity" = "1" ]; then
		echo "Logging progress to console"
	else
		echo "Logging only important steps"
	fi

	for dir in ${dirs[@]}; do
			
		sounds=$(find "$dir" -type f -name '*.wav')
echo " "
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$dir" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo "Converting soundfont in "${dir}

		targetpath="Converted_to_Proffie/${dir}"
		mkdir -p "$targetpath"

    	for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -Ab --no-perms "${o}" "$targetpath"
		done
		if [[ "${sounds[*]}" == *rack* ]]; then
			mkdir -p "$targetpath/tracks"
			echo "Moving all tracks to converted folder"
			rsync -rAb --no-perms ${dir}/*rack* "$targetpath/tracks"
		fi
		if [[ "${sounds[*]}" == *xtra* ]]; then
			mkdir -p "$targetpath/extras"
			echo "Moving all extras to converted folder"
			rsync -rAb --no-perms ${dir}/*xtra*/ "$targetpath/extras"
		fi

		blastercounter=1
		bootcounter=1
		clashcounter=1
		colorcounter=1
		dragcounter=1
		endlockcounter=1
		extracounter=1
		fontcounter=1
		forcecounter=1
		hiddencounter=1
		hswingcounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		lswingcounter=1
		outcounter=1
		preoncounter=1
		spincounter=1
		stabcounter=1
		swingcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			if [[ "${src}" == *._* ]]; then
				if [[ $hiddencounter = 1 ]]; then
					echo "- Hidden files found and ignored."
					hiddencounter=$((hiddencounter+1))	
				fi
				continue;
			fi
			if [[ "${src}" == *xtra* ]]; then
				if [[ $extracounter = 1 ]]; then
					echo "Already moved extras."
					extracounter=$((extracounter+1))	
				fi
				continue;
			fi
			# Move tracks folder as-is.
			if [[ "${src}" == *rack* ]]; then
				if [[ $trackcounter = 1 ]]; then
					echo "Already moved tracks."
					trackcounter=$((trackcounter+1))	
				fi
				continue;
			fi

			case "${src##*/}" in

				blaster**([0-9]).wav)
					if [ $blastercounter = 2 ]; then
						mkdir -p "$targetpath/blst"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/blst/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/blst subfolder"
					fi
					if [ "$blastercounter" -lt 10 ]; then 
						targetfile=$(printf %q "blst0$blastercounter.wav")	
					else
						targetfile=$(printf %q "blst$blastercounter.wav")
					fi
					if [ $blastercounter -ge 2 ]; then
						target="./$targetpath/blst/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					blastercounter=$((blastercounter+1))
				;;
	
				*clash**([0-9]).wav)
					if [ $clashcounter = 2 ]; then
						mkdir -p "$targetpath/clsh"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/clsh/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/clsh subfolder"
					fi
					if [ "$clashcounter" -lt 10 ]; then 
						targetfile=$(printf %q "clsh0$clashcounter.wav")	
					else
						targetfile=$(printf %q "clsh$clashcounter.wav")
					fi
					if [ $clashcounter -ge 2 ]; then
						target="./$targetpath/clsh/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					clashcounter=$((clashcounter+1))
				;;
				
				color**([0-9]).wav)
					if [ $colorcounter = 2 ]; then
						mkdir -p "$targetpath/ccchange"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/ccchange/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/ccchange subfolder"
					fi
					if [ "$colorcounter" -lt 10 ]; then 
						targetfile=$(printf %q "ccchange0$colorcounter.wav")	
					else
						targetfile=$(printf %q "ccchange$colorcounter.wav")
					fi
					if [ $colorcounter -ge 2 ]; then
						target="./$targetpath/ccchange/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					colorcounter=$((colorcounter+1))
				;;
				
				drag**([0-9]).wav)
					if [ $dragcounter = 2 ]; then
						mkdir -p "$targetpath/drag"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/drag/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/drag subfolder"
					fi
					if [ "$dragcounter" -lt 10 ]; then 
						targetfile=$(printf %q "drag0$dragcounter.wav")	
					else
						targetfile=$(printf %q "drag$dragcounter.wav")
					fi
					if [ $dragcounter -ge 2 ]; then
						target="./$targetpath/drag/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					dragcounter=$((dragcounter+1))
				;;
				
				endlock**([0-9]).wav)
					if [ $endlockcounter = 2 ]; then
						mkdir -p "$targetpath/endlock"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/endlock/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/endlock subfolder"
					fi
						targetfile=$(printf %q "endlock$endlockcounter.wav")
					if [ $endlockcounter -ge 2 ]; then
						target="./$targetpath/endlock/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					endlockcounter=$((endlockcounter+1))
				;;
				
				font**([0-9]).wav)
					if [ $fontcounter = 2 ]; then
						mkdir -p "$targetpath/font"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/font/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/font subfolder"
					fi
					if [ "$fontcounter" -lt 10 ]; then 
						targetfile=$(printf %q "font0$fontcounter.wav")	
					else
						targetfile=$(printf %q "font$fontcounter.wav")
					fi
					if [ $fontcounter -ge 2 ]; then
						target="./$targetpath/font/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					fontcounter=$((fontcounter+1))
				;;
				
				force**([0-9]).wav)
					if [ $forcecounter = 2 ]; then
						mkdir -p "$targetpath/force"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/force/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/force subfolder"
					fi
					if [ "$forcecounter" -lt 10 ]; then 
						targetfile=$(printf %q "force0$forcecounter.wav")	
					else
						targetfile=$(printf %q "force$forcecounter.wav")
					fi
					if [ $forcecounter -ge 2 ]; then
						target="./$targetpath/force/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					forcecounter=$((forcecounter+1))
				;;
				
				hswing**|swingh**([0-9]).wav)
					if [ $hswingcounter = 2 ]; then
						mkdir -p "$targetpath/swingh"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/swingh/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/swingh subfolder"
					fi
					if [ "$hswingcounter" -lt 10 ]; then 
						targetfile=$(printf %q "swingh0$hswingcounter.wav")	
					else
						targetfile=$(printf %q "swingh$hswingcounter.wav")
					fi
					if [ $hswingcounter -ge 2 ]; then
						target="./$targetpath/swingh/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					hswingcounter=$((hswingcounter+1))
				;;

				hum**([0-9]).wav)
					if [ $humcounter = 2 ]; then
						mkdir -p "$targetpath/hum"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/hum/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/hum subfolder"
					fi
					if [ "$humcounter" -lt 10 ]; then 
						targetfile=$(printf %q "hum0$humcounter.wav")	
					else
						targetfile=$(printf %q "hum$humcounter.wav")
					fi
					if [ $humcounter -ge 2 ]; then
						target="./$targetpath/hum/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					humcounter=$((humcounter+1))
				;;

				lswing**|swingl**([0-9]).wav)
					if [ $lswingcounter = 2 ]; then
						mkdir -p "$targetpath/swingl"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/swingl/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/swingl subfolder"
					fi
					if [ "$lswingcounter" -lt 10 ]; then 
						targetfile=$(printf %q "swingl0$lswingcounter.wav")	
					else
						targetfile=$(printf %q "swingl$lswingcounter.wav")
					fi
					if [ $lswingcounter -ge 2 ]; then
						target="./$targetpath/swingl/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					lswingcounter=$((lswingcounter+1))
				;;

				in**([0-9]).wav)
					if [ $incounter = 2 ]; then
						mkdir -p "$targetpath/in"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/in/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/in subfolder"
					fi
					if [ "$incounter" -lt 10 ]; then 
						targetfile=$(printf %q "in0$incounter.wav")	
					else
						targetfile=$(printf %q "in$incounter.wav")
					fi
					if [ $incounter -ge 2 ]; then
						target="./$targetpath/in/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					incounter=$((incounter+1))
				;;

				out**([0-9]).wav)
					if [ $outcounter = 2 ]; then
						mkdir -p "$targetpath/out"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/out/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/out subfolder"
					fi
					if [ "$outcounter" -lt 10 ]; then 
						targetfile=$(printf %q "out0$outcounter.wav")	
					else
						targetfile=$(printf %q "out$outcounter.wav")
					fi
					if [ $outcounter -ge 2 ]; then
						target="./$targetpath/out/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					outcounter=$((outcounter+1))
				;;

				lock**([0-9]).wav)
					if [ $lockcounter = 2 ]; then
						mkdir -p "$targetpath/lock"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/lock/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/lock subfolder"
					fi
					if [ "$lockcounter" -lt 10 ]; then 
						targetfile=$(printf %q "lock0$lockcounter.wav")	
					else
						targetfile=$(printf %q "lock$lockcounter.wav")
					fi
					if [ $lockcounter -ge 2 ]; then
						target="./$targetpath/lock/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					lockcounter=$((lockcounter+1))
				;;

				preon**([0-9]).wav)
					if [ $preoncounter = 2 ]; then
						mkdir -p "$targetpath/preon"
					rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/preon/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/preon subfolder"
					fi
					if [ "$preoncounter" -lt 10 ]; then 
						targetfile=$(printf %q "preon0$preoncounter.wav")	
					else
						targetfile=$(printf %q "preon$preoncounter.wav")
					fi
					if [ $preoncounter -ge 2 ]; then
						target="./$targetpath/preon/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					preoncounter=$((preoncounter+1))
				;;

				spin**([0-9]).wav)
					if [ $spincounter = 2 ]; then
						mkdir -p "$targetpath/spin"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/spin/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/spin subfolder"
					fi
					if [ "$spincounter" -lt 10 ]; then 
						targetfile=$(printf %q "spin0$spincounter.wav")	
					else
						targetfile=$(printf %q "spin$spincounter.wav")
					fi
					if [ $spincounter -ge 2 ]; then
						target="./$targetpath/spin/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					spincounter=$((spincounter+1))
				;;

				stab**([0-9]).wav)
					if [ $stabcounter = 2 ]; then
						mkdir -p "$targetpath/stab"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/stab/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/stab subfolder"
					fi
					if [ "$stabcounter" -lt 10 ]; then 
						targetfile=$(printf %q "stab0$stabcounter.wav")	
					else
						targetfile=$(printf %q "stab$stabcounter.wav")
					fi
					if [ $stabcounter -ge 2 ]; then
						target="./$targetpath/stab/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					stabcounter=$((stabcounter+1))
				;;

				swing**([0-9]).wav)
					if [ $swingcounter = 2 ]; then
						mkdir -p "$targetpath/swng"
						rsync -Ab --no-perms --remove-source-files "${target}" "./$targetpath/swng/${targetfile}"
						echo "Moving ${targetfile} into ${dir}/swng subfolder"
					fi
					if [ "$swingcounter" -lt 10 ]; then 
						targetfile=$(printf %q "swng0$swingcounter.wav")	
					else
						targetfile=$(printf %q "swng$swingcounter.wav")
					fi
					if [ $swingcounter -ge 2 ]; then
						target="./$targetpath/swng/${targetfile}"
					else
						target="./$targetpath/$targetfile"
					fi
					if [ "$verbosity" = "1" ]; then
						echo "Converting ${src} to ${target}"
					fi
					rsync -Ab --no-perms "${src}" "${target}"
					swingcounter=$((swingcounter+1))
					;;

				
				*)
					echo "No match found, or not suppoted in target format. ignoring file "$src

			esac
		done
		echo " "
		echo "Converted soundfont saved in "$targetpath
		echo " "
	done

	echo "Soundfont conversion complete. If you see files with a '~' at the end, this file already existed in the output folder"
	echo "before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"
else
	echo "Invalid conversion choice, please run the tool again."
	echo " "
	echo " "
fi
