#!/bin/sh
	shopt -s extglob
	IFS=$'\n'

	echo " "
	echo "***********************************************************************"
	echo " Hello Saberfans! Welcome to the Soundfont Naming Converter."
	echo " - by @Mormegil and @NoSloppy - 2021"
	echo "***********************************************************************"
	echo " "
	echo " ** Please keep in mind, there's no reason to convert TO Proffie naming,"
	echo " ** because ProffieOS already supports other boards' fonts as they are."
	echo " "
	echo "To rename a Proffie soundfont for ideal performance,   enter 'PtoP'"
	echo " "
	echo "To convert a soundfont from CFX to GoldenHarvest,      enter 'CtoG'"
	echo "To convert a soundfont from CFX to Xenopixel,          enter 'CtoX'"
	echo " "
	echo "To convert a soundfont from Proffie to CFX,            enter 'PtoC'"
	echo "To convert a soundfont from Proffie to GoldenHarvest,  enter 'PtoG'"
	echo "To convert a soundfont from Proffie to Xenopixel,      enter 'PtoX'"
	echo " "
	echo "To convert a soundfont from Xenopixel to CFX,          enter 'XtoC'"
	echo "To convert a soundfont from Xenopixel to GoldenHarvest,enter 'XtoG'"
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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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
echo "Sounds to rename/organize:"
echo "${sounds[*]}"
		otherfiles=$(find "$font" -type f ! -name '*.wav' -and ! -name '.*')
		echo " "
echo "Other files to move:"
echo "${otherfiles[*]}"
echo " "
		echo Converting soundfont in "${font}".

		targetpath="Converted_to_Proper_Proffie"
		mkdir -p "${targetpath}/${font}"

		if [[ ! " ${otherfiles[*]} " =~ ${font}'/config.ini' ]]; then
    		echo "Adding missing config.ini"
    		rsync -ab "./inis/config.ini" "${targetpath}/${font}"
    	fi
		if [[ ! " ${otherfiles[*]} " =~ ${font}'/smoothsw.ini' ]]; then
    		echo "Adding missing smoothsw.ini"
    		rsync -ab "./inis/smoothsw.ini" "${targetpath}/${font}"
    	fi

		for o in ${otherfiles}; do
			echo "Moving "${o}" to converted folder"
			rsync -ab "${o}" "${targetpath}/${font}"
		done
		if [ -d "${font}/tracks" ]; then
			mkdir -p "${targetpath}/${font}/tracks"
			echo "Moving tracks to converted folder"
			rsync -ab "${font}/tracks/" "${targetpath}/${font}/tracks"
		fi

		counter=1
		oldeffect="old"

		for src in ${sounds[@]}; do
			# Move tracks folder as-is.
			if [[ "${src}" == *"tracks"* ]]; then
				echo "Already moved tracks."
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
				mv "${target}" "./${targetpath}/${font}/${effect}/${targetfile}"
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
			rsync -ab  "${src}" "${target}"
			# increment counter for next effect sound
			counter=$((counter+1))
			oldeffect="${effect}"
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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

		echo Converting soundfont in "${dir}".

		targetpath="Converted_to_GoldenHarvest/${dir}"
		mkdir -p "${targetpath}"

		startdragounter=1
		startlockcounter=1
		blastercounter=1
		bootcounter=1
		colorcounter=1
		clashcounter=1
		dragcounter=1
		enddragcounter=1
		endlockcounter=1
		fontcounter=1
		forcecounter=1
		hswingcounter=1
		humMcounter=1
		lockupcounter=1
		lswingcounter=1
		preoncounter=1
		# pstoffcounter=1
		poweroffcounter=1
		poweroncounter=1
		# savecounter=1
		spincounter=1
		stabcounter=1
		swingcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			case "${src##*/}" in

				startdrag*([0-9]).wav)
				targetfile=$(printf %q "bgndrag$startdragcounter.wav")
				startdragcounter=$((startdragcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;

				startlock*([0-9]).wav)
				targetfile=$(printf %q "bgnlock$startlockcounter.wav")
				startlockcounter=$((startlockcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;

				blaster*([0-9]).wav)
				targetfile=$(printf %q "blast$blastercounter.wav")
				blastercounter=$((blastercounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;
				
				boot*([0-9]).wav)
				targetfile=$(printf %q "boot$bootcounter.wav")
				bootcounter=$((bootcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;
				
				color*([0-9]).wav)
				targetfile=$(printf %q "change$colorcounter.wav")
				colorcounter=$((colorcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				clash*([0-9]).wav)
				targetfile=$(printf %q "clash$clashcounter.wav")
				clashcounter=$((clashcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				drag*([0-9]).wav)
				targetfile=$(printf %q "drag$dragcounter.wav")
				dragcounter=$((dragcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				enddrag*([0-9]).wav)
				targetfile=$(printf %q "enddrag$enddragcounter.wav")
				enddragcounter=$((enddragcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				endlock*([0-9]).wav)
				targetfile=$(printf %q "endlock$endlockcounter.wav")
				endlockcounter=$((endlockcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				font*([0-9]).wav)
				targetfile=$(printf %q "font.wav")
				#fontcounter=$((fontcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				force*|quote*([0-9]).wav)
				targetfile=$(printf %q "force$forcecounter.wav")
				forcecounter=$((forcecounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				hswing*([0-9]).wav)
				targetfile=$(printf %q "hswing$hswingcounter.wav")
				hswingcounter=$((hswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				humM*([0-9]).wav)
				targetfile=$(printf %q "hum$humMcounter.wav")
				humMcounter=$((humMcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				lockup*([0-9]).wav)
				targetfile=$(printf %q "lock$lockupcounter.wav")
				lockupcounter=$((lockupcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				lswing*([0-9]).wav)
				targetfile=$(printf %q "lswing$lswingcounter.wav")
				lswingcounter=$((lswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				preon*([0-9]).wav)
				targetfile=$(printf %q "preon$preoncounter.wav")
				preoncounter=$((preoncounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

	# pstoff sounds are currently not supported by GoldenHarvest and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 			pstoff**([0-9]).wav)
	# 			targetfile=$(printf %q "pstoff$pstoffcounter.wav")
	# 			pstoffcounter=$((pstoffcounter+1))
	# 			target="./${targetpath}/${dir}/pstoff/${targetfile}"
	# 			if [ "$verbosity" = "1" ]; then
	# 				echo "Converting ${src} to ${target}"
	# 			fi
	# 			rsync -ab "${src}" "${target}" 
	# 			;;

				poweroff|pwroff*([0-9]).wav)
				targetfile=$(printf %q "pwroff$poweroffcounter.wav")
				poweroffcounter=$((poweroffcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				poweron*([0-9]).wav)
				targetfile=$(printf %q "pwron$poweroncounter.wav")
				poweroncounter=$((poweroncounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

	# save sounds are currently only supported by GoldenHarvest and therefore ignored
	# since the source has nothing to provide. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 			save*([0-9]).wav)
	# 			targetfile=$(printf %q "save$savecounter.wav")
	# 			savecounter=$((savecounter+1))
	# 			target="./${targetpath}/${dir}/${targetfile}"
	# 			if [ "$verbosity" = "1" ]; then
	# 				echo "Converting ${src} to ${target}"
	# 			fi
	# 			rsync -ab "${src}" "${target}" 
	# 			;;

				spin*([0-9]).wav)
				targetfile=$(printf %q "spin$spincounter.wav")
				spincounter=$((spincounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				stab*([0-9]).wav)
				targetfile=$(printf %q "stab$stabcounter.wav")
				stabcounter=$((stabcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				swing*([0-9]).wav)
				targetfile=$(printf %q "swing$swingcounter.wav")
				swingcounter=$((swingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				track*([0-9]).wav)
				targetfile=$(printf %q "track$trackcounter.wav")
				trackcounter=$((trackcounter+1))
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				*)
				echo "No match found, ignoring file $src"

			esac
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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

		echo Converting soundfont in "${dir}".

		targetpath="Converted_to_Xenopixel"
		mkdir -p "${targetpath}"
	    mkdir -p "${targetpath}/${dir}/set"
	    mkdir -p "${targetpath}/${dir}/tracks"
		blastercounter=1
		bootcounter=1
		clashcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		fontcounter=1
		forcecounter=1
		hswingcounter=1
		humcounter=1
		lswingcounter=1
		poweroffcounter=1
		poweroncounter=1
		lockcounter=1
		lockupcounter=1
		preoncounter=1
		# spincounter=1
		# stabcounter=1
		# swingcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			case "${src##*/}" in

			blaster*([0-9]).wav)
			targetfile="blaster ($blastercounter).wav"
			blastercounter=$((blastercounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}" 
			;;
			
	# boot sounds are converted to 'power on.wav and live in the 'set' folder.
	# If there are more than one converted, the last one will be the resulting file.
			boot*([0-9]).wav)
			targetfile="power on.wav"
			bootcounter=$((bootcounter+1))
			target="./$targetpath/${dir}/set/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}" 
			;;
			
			clash*([0-9]).wav)
			targetfile="clash ($clashcounter).wav"
			clashcounter=$((clashcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
	# color sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.			
	# 		color*([0-9]).wav)
	# 		targetfile="color ($colorcounter).wav"
	# 		colorcounter=$((colorcounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;
			
			drag*([0-9]).wav)
			targetfile="drag ($dragcounter).wav"
			dragcounter=$((dragcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
	# endlock sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.	
	# 		endlock*([0-9]).wav)
	# 		targetfile="endlock ($endlockcounter).wav"
	# 		endlockcounter=$((endlockcounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;
			
			font*([0-9]).wav)
			targetfile="font ($fontcounter).wav"
			fontcounter=$((fontcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			force*|combo*([0-9]).wav)
			targetfile="force ($forcecounter).wav"
			forcecounter=$((forcecounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			hum*|humM*([0-9]).wav)
			targetfile="hum ($humcounter).wav"
			humcounter=$((humcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			poweroff*|pwroff*([0-9]).wav)
			targetfile="in ($poweroffcounter).wav"
			poweroffcounter=$((poweroffcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			lock**([0-9]).wav)
			targetfile="lock ($lockcounter).wav"
			lockcounter=$((lockcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			poweron**([0-9]).wav)
			targetfile="out ($poweroncounter).wav"
			poweroncounter=$((poweroncounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;

			hswing*([0-9]).wav)
			targetfile="hswing ($hswingcounter).wav"
			hswingcounter=$((hswingcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			lswing*([0-9]).wav)
			targetfile="lswing ($lswingcounter).wav"
			lswingcounter=$((lswingcounter+1))
			target="./$targetpath//${dir}/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;

			preon*([0-9]).wav)
			targetfile="preon ($preoncounter).wav"
			if [ "$preoncounter" -ge 5 ]; then
				preoncounter=1
			else
				preoncounter=$((preoncounter+1))
			fi
			target="./$targetpath/$targetfile"
			target="./$targetpath/${dir}/set/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;

	# spin sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 		spin*([0-9]).wav)
	# 		targetfile="spin ($spincounter).wav"
	# 		spincounter=$((spincounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;		

	# stab sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 		stab*([0-9]).wav)
	# 		targetfile="stab ($stabcounter).wav"
	# 		stabcounter=$((stabcounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;

	# Accent Swings are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment and adapt targetfile if needed later.		
	# 		swng*([0-9]).wav)
	# 		targetfile="swing ($swingcounter).wav"
	# 		swingcounter=$((swingcounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;
			
			track*([0-9]).wav)
			targetfile="track ($trackcounter).wav"
			trackcounter=$((trackcounter+1))
			target="./$targetpath/${dir}/tracks/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
				
				*)
				echo "No match found, ignoring file $src"

			esac
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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

		echo Converting soundfont in "${dir}".

		targetpath="Converted_to_CFX/${dir}"
		mkdir -p "${targetpath}"

		bgndragcounter=1
		bgnlockcounter=1
		blstcounter=1
		bootcounter=1
		clshcounter=1
		ccchangecounter=1
		dragcounter=1
		enddragcounter=1
		endlockcounter=1
		fontcounter=1
		forcecounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		outcounter=1
		preoncounter=1
		spincounter=1
		stabcounter=1
		swinghcounter=1
		swinglcounter=1
		swngcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			case "${src##*/}" in

				bgndrag*([0-9]).wav)
				targetfile=$(printf %q "startdrag$bgndragcounter.wav")
				bgndragcounter=$((bgndragcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;

				bgnlock*([0-9]).wav)
				targetfile=$(printf %q "startlock$bgnlockcounter.wav")
				bgnlockcounter=$((bgnlockcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;

				blst*([0-9]).wav)
				if [ "$blstcounter" -eq 1 ]; then 
					targetfile=$(printf %q "blaster.wav")	
				else
					targetfile=$(printf %q "blaster$blstcounter.wav")
				fi
				blstcounter=$((blstcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
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
				rsync -ab "${src}" "${target}" 
				;;
				
				clsh*([0-9]).wav)
				targetfile=$(printf %q "clash$clshcounter.wav")
				clshcounter=$((clshcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				ccchange*([0-9]).wav)
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
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
				;;

				enddrag*([0-9]).wav)
				targetfile=$(printf %q "enddrag$enddragcounter.wav")
				enddragcounter=$((enddragcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				endlock*([0-9]).wav)
				targetfile=$(printf %q "endlock$endlockcounter.wav")
				endlockcounter=$((endlockcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
				;;
				
				hum*([0-9]).wav)
				targetfile=$(printf %q "humM$humcounter.wav")
				humcounter=$((humcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
				;;

				preon*([0-9]).wav)
				targetfile=$(printf %q "preon$preoncounter.wav")
				preoncounter=$((preoncounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				spin*([0-9]).wav)
				targetfile=$(printf %q "spin$spincounter.wav")
				spincounter=$((spincounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				stab*([0-9]).wav)
				targetfile=$(printf %q "stab$stabcounter.wav")
				stabcounter=$((stabcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				swingh*([0-9]).wav)
				targetfile=$(printf %q "hswing$swinghcounter.wav")
				swinghcounter=$((swinghcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				swingl*([0-9]).wav)
				targetfile=$(printf %q "lswing$swinglcounter.wav")
				swinglcounter=$((swinglcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				swng*([0-9]).wav)
				targetfile=$(printf %q "swing$swngcounter.wav")
				swngcounter=$((swngcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				track*([0-9]).wav)
				targetfile=$(printf %q "track$trackcounter.wav")
				trackcounter=$((trackcounter+1))
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				*)
				echo "No match found, ignoring file $src"

			esac
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
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
	echo "- If you have multiple font.wavs in the source font, the last one will be used"
	echo "- save.wav generated from endlb file. "
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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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

		echo Converting soundfont in "${dir}".

		targetpath="Converted_to_GoldenHarvest/${dir}"
		mkdir -p "${targetpath}"

		bgndragcounter=1
		bgnlockcounter=1
		blstcounter=1
		bootcounter=1
		clshcounter=1
		ccchangecounter=1
		dragcounter=1
		enddragcounter=1
		endlockcounter=1
		fontcounter=1
		forcecounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		outcounter=1
		preoncounter=1
		spincounter=1
		stabcounter=1
		swinghcounter=1
		swinglcounter=1
		swngcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			case "${src##*/}" in

				bgndrag*([0-9]).wav)
				targetfile=$(printf %q "bgndrag$bgndragcounter.wav")
				bgndragcounter=$((bgndragcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;

				bgnlock*([0-9]).wav)
				targetfile=$(printf %q "bgnlock$bgnlockcounter.wav")
				bgnlockcounter=$((bgnlockcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;

				blst*([0-9]).wav)
				targetfile=$(printf %q "blast$blstcounter.wav")
				blstcounter=$((blstcounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;
				
				boot*([0-9]).wav)
				targetfile=$(printf %q "boot$bootcounter.wav")
				bootcounter=$((bootcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;
				
				clsh*([0-9]).wav)
				targetfile=$(printf %q "clash$clshcounter.wav")
				clshcounter=$((clshcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				ccchange*([0-9]).wav)
				targetfile=$(printf %q "change$ccchangecounter.wav")
				ccchangecounter=$((ccchangecounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				drag*([0-9]).wav)
				targetfile=$(printf %q "drag$dragcounter.wav")
				dragcounter=$((dragcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				enddrag*([0-9]).wav)
				targetfile=$(printf %q "enddrag$enddragcounter.wav")
				enddragcounter=$((enddragcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				endlock*([0-9]).wav)
				targetfile=$(printf %q "endlock$endlockcounter.wav")
				endlockcounter=$((endlockcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				font*([0-9]).wav)
				#fontcounter=$((fontcounter+1))
				targetfile=$(printf %q "font.wav")
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				force*|quote*([0-9]).wav)
				targetfile=$(printf %q "force$forcecounter.wav")
				forcecounter=$((forcecounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				hum*([0-9]).wav)
				targetfile=$(printf %q "hum$humcounter.wav")
				humcounter=$((humcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				in*([0-9]).wav)
				targetfile=$(printf %q "pwroff$incounter.wav")
				incounter=$((incounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				lock*([0-9]).wav)
				targetfile=$(printf %q "lockup$lockcounter.wav")
				lockcounter=$((lockcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				out*([0-9]).wav)
				targetfile=$(printf %q "pwron$outcounter.wav")
				outcounter=$((outcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				preon*([0-9]).wav)
				targetfile=$(printf %q "preon$preoncounter.wav")
				preoncounter=$((preoncounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				endlb*([0-9]).wav)
				targetfile=$(printf %q "save.wav")
				target="./${targetpath}/${dir}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;

				spin*([0-9]).wav)
				targetfile=$(printf %q "spin$spincounter.wav")
				spincounter=$((spincounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				stab*([0-9]).wav)
				targetfile=$(printf %q "stab$stabcounter.wav")
				stabcounter=$((stabcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				swingh*([0-9]).wav)
				targetfile=$(printf %q "hswing$swinghcounter.wav")
				swinghcounter=$((swinghcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				swingl*([0-9]).wav)
				targetfile=$(printf %q "lswing$swinglcounter.wav")
				swinglcounter=$((swinglcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				swng*([0-9]).wav)
				targetfile=$(printf %q "swing$swngcounter.wav")
				swngcounter=$((swngcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				track*([0-9]).wav)
				targetfile=$(printf %q "track$trackcounter.wav")
				trackcounter=$((trackcounter+1))
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				*)
				echo "No match found, ignoring file $src"

			esac
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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

		echo Converting soundfont in "${dir}".

		targetpath="Converted_to_Xenopixel"
		mkdir -p "${targetpath}"
	    mkdir -p "${targetpath}/${dir}/set"
	    mkdir -p "${targetpath}/${dir}/tracks"

		blstcounter=1
		bootcounter=1
		clshcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		fontcounter=1
		forcecounter=1
		humcounter=1
		incounter=1
		lockcounter=1
		outcounter=1
		preoncounter=1
		swinghcounter=1
		swinglcounter=1
		# spincounter=1
		# stabcounter=1
		# swngcounter=1
		trackcounter=1

		for src in ${sounds[@]}; do
			case "${src##*/}" in
			blst*([0-9]).wav)
			targetfile="blaster ($blstcounter).wav"
			blstcounter=$((blstcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}" 
			;;
				
	# boot sounds are converted to 'power on.wav and live in the 'set' folder.
	# If there are more than one converted, the last one will be the resulting file.
			boot*([0-9]).wav)
			targetfile="power on.wav"
			bootcounter=$((bootcounter+1))
			target="./$targetpath/${dir}/set/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}" 
			;;
			
			clsh*([0-9]).wav)
			targetfile="clash ($clshcounter).wav"
			clshcounter=$((clshcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
		 # color sounds are currently not supported by Xenopixel and therefore ignored. 
		 # Uncomment counter above and code here and adapt targetfile if needed later.			
		 # 	color*([0-9]).wav)
		 # 	targetfile="color ($colorcounter).wav"
		 # 	colorcounter=$((colorcounter+1))
			# target="./${targetpath}/${dir}/${targetfile}"
		 # 	if [ "$verbosity" = "1" ]; then
		 # 		echo "Converting ${src} to ${target}"
		 # 	fi
		 # 	rsync -ab "${src}" "${target}"
		 # 	;;
			
			drag*([0-9]).wav)
			targetfile="drag ($dragcounter).wav"
			dragcounter=$((dragcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
		# endlock sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.	
		# 	endlock*([0-9]).wav)
		# 	targetfile="endlock ($endlockcounter).wav"
		# 	endlockcounter=$((endlockcounter+1))
		# 	target="./${targetpath}/${dir}/${targetfile}"
		# 	if [ "$verbosity" = "1" ]; then
		# 		echo "Converting ${src} to ${target}"
		# 	fi
		# 	rsync -ab "${src}" "${target}"
		#  	;;
			
			font*([0-9]).wav)
			targetfile="font ($fontcounter).wav"
			fontcounter=$((fontcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			force*|quote*([0-9]).wav)
			targetfile="force ($forcecounter).wav"
			forcecounter=$((forcecounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			hum*([0-9]).wav)
			targetfile="hum ($humcounter).wav"
			humcounter=$((humcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			in*([0-9]).wav)
			targetfile="in ($incounter).wav"
			incounter=$((incounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			lock*([0-9]).wav)
			targetfile="lock ($lockcounter).wav"
			lockcounter=$((lockcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			out*([0-9]).wav)
			targetfile="out ($outcounter).wav"
			outcounter=$((outcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			swingh*([0-9]).wav)
			targetfile="swingh ($swinghcounter).wav"
			swinghcounter=$((swinghcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
			swingl*([0-9]).wav)
			targetfile="swingl ($swinglcounter).wav"
			swinglcounter=$((swinglcounter+1))
			target="./${targetpath}/${dir}/${targetfile}"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;

			preon*([0-9]).wav)
			targetfile="preon ($preoncounter).wav"
			if [ "$preoncounter" -ge 5 ]; then
				preoncounter=1
			else
				preoncounter=$((preoncounter+1))
			fi
			target="./$targetpath/$targetfile"
			target="./$targetpath/${dir}/set/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;

	# spin sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 		spin*([0-9]).wav)
	# 		targetfile="spin ($spincounter).wav"
	# 		spincounter=$((spincounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;		

	# stab sounds are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment counter above and code here and adapt targetfile if needed later.
	# 		stab*([0-9]).wav)
	# 		targetfile="stab ($stabcounter).wav"
	# 		stabcounter=$((stabcounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;
	# Accent Swings are currently not supported by Xenopixel and therefore ignored. 
	# Uncomment and adapt targetfile if needed later.		
	# 		swng*([0-9]).wav)
	# 		targetfile="swing ($swingcounter).wav"
	# 		swingcounter=$((swingcounter+1))
	#		target="./${targetpath}/${dir}/${targetfile}"
	# 		if [ "$verbosity" = "1" ]; then
	# 			echo "Converting ${src} to ${target}"
	# 		fi
	# 		rsync -ab "${src}" "${target}"
	# 		;;
				
			track*([0-9]).wav)
			targetfile="track ($trackcounter).wav"
			trackcounter=$((trackcounter+1))
			target="./$targetpath/${dir}/tracks/$targetfile"
			if [ "$verbosity" = "1" ]; then
				echo "Converting ${src} to ${target}"
			fi
			rsync -ab "${src}" "${target}"
			;;
			
				*)
				echo "No match found, ignoring file $src"

			esac
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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

		echo Converting soundfont in "${dir}".

		targetpath="Converted_to_CFX/${dir}"
		mkdir -p "${targetpath}"
	
		blastercounter=1
		# bootcounter=1
		clashcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		fontcounter=1
		forcecounter=1
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
			case "${src##*/}" in

				blaster**([0-9]).wav)
				if [ "$blastercounter" -eq 1 ]; then 
					targetfile=$(printf %q "blaster.wav")	
				else
					targetfile=$(printf %q "blaster$blastercounter.wav")
				fi
				blastercounter=$((blastercounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;
				
		# boot sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		boot**([0-9]).wav)
		# 		targetfile=$(printf %q "boot$bootcounter.wav")
		# 		bootcounter=$((bootcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}" 
		# 		;;
				
				clash**([0-9]).wav)
				targetfile=$(printf %q "clash$clashcounter.wav")
				clashcounter=$((clashcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
		# color sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		color**([0-9]).wav)
		# 		targetfile=$(printf %q "color$colorcounter.wav")
		# 		colorcounter=$((colorcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
				;;

		# endlock sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.	
		# 		endlock*([0-9]).wav)
		# 		targetfile=$(printf %q "endlock$endlockcounter.wav")
		# 		endlockcounter=$((endlockcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
				;;
				
				hum**([0-9]).wav)
				targetfile=$(printf %q "humM$humcounter.wav")
				humcounter=$((humcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
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
				rsync -ab "${src}" "${target}"
				;;

				hswing**([0-9]).wav)
				targetfile=$(printf %q "hswing$hswingcounter.wav")
				hswingcounter=$((hswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				lswing**([0-9]).wav)
				targetfile=$(printf %q "lswing$lswingcounter.wav")
				lswingcounter=$((lswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

		# Accent Swings are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment and adapt targetfile if needed later.	
		# 		swng**([0-9]).wav)
		# 		targetfile=$(printf %q "swing$swingcounter.wav")
		# 		swingcounter=$((swingcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}"
		# 		;;
				
				track**([0-9]).wav)
				targetfile=$(printf %q "track$trackcounter.wav")
				trackcounter=$((trackcounter+1))
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				*)
				echo "No match found, ignoring file $src"

			esac
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
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

		if [ "$input2" = "y" ]; then
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

		if [ "$input2" = "y" ]; then
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

		echo Converting soundfont in "${dir}".

		targetpath="Converted_to_GoldenHarvest/${dir}"
		mkdir -p "${targetpath}"
	
		blastercounter=1
		# bootcounter=1
		clashcounter=1
		# colorcounter=1
		dragcounter=1
		# endlockcounter=1
		fontcounter=1
		forcecounter=1
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
			case "${src##*/}" in

				blaster**([0-9]).wav)
				targetfile=$(printf %q "blast$blastercounter.wav")
				blastercounter=$((blastercounter+1))
				target="./${targetpath}/${targetfile}"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}" 
				;;
				
		# boot sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		boot**([0-9]).wav)
		# 		targetfile=$(printf %q "boot$bootcounter.wav")
		# 		bootcounter=$((bootcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}" 
		# 		;;
				
				clash**([0-9]).wav)
				targetfile=$(printf %q "clash$clashcounter.wav")
				clashcounter=$((clashcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
		# color sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.
		# 		color**([0-9]).wav)
		# 		targetfile=$(printf %q "color$colorcounter.wav")
		# 		colorcounter=$((colorcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}"
		# 		;;
				
				drag**([0-9]).wav)
				targetfile=$(printf %q "drag$dragcounter.wav")
				dragcounter=$((dragcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

		# endlock sounds are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment counter above and code here and adapt targetfile if needed later.	
		# 		endlock*([0-9]).wav)
		# 		targetfile=$(printf %q "endlock$endlockcounter.wav")
		# 		endlockcounter=$((endlockcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}"
		# 		;;
				
				font**([0-9]).wav)
				targetfile=$(printf %q "font.wav")	
				# fontcounter=$((fontcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				force**([0-9]).wav)
				targetfile=$(printf %q "force$forcecounter.wav")
				forcecounter=$((forcecounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				hum**([0-9]).wav)
				targetfile=$(printf %q "hum$humcounter.wav")
				humcounter=$((humcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				in**([0-9]).wav)
				targetfile=$(printf %q "pwroff$incounter.wav")
				incounter=$((incounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				lock**([0-9]).wav)
				targetfile=$(printf %q "lockup$lockcounter.wav")
				lockcounter=$((lockcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				out*([0-9]).wav)
				targetfile=$(printf %q "pwron$outcounter.wav")
				outcounter=$((outcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

				hswing**([0-9]).wav)
				targetfile=$(printf %q "hswing$hswingcounter.wav")
				hswingcounter=$((hswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				lswing**([0-9]).wav)
				targetfile=$(printf %q "lswing$lswingcounter.wav")
				lswingcounter=$((lswingcounter+1))
				target="./$targetpath/$targetfile"
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;

		# Accent Swings are currently not supported by Xenopixel and therefore ignored. 
		# Uncomment and adapt targetfile if needed later.	
		# 		swng**([0-9]).wav)
		# 		targetfile=$(printf %q "swing$swingcounter.wav")
		# 		swingcounter=$((swingcounter+1))
		# 		target="./$targetpath/$targetfile"
		# 		if [ "$verbosity" = "1" ]; then
		# 			echo "Converting ${src} to ${target}"
		# 		fi
		# 		rsync -ab "${src}" "${target}"
		# 		;;
				
				track**([0-9]).wav)
				targetfile=$(printf %q "track$trackcounter.wav")
				trackcounter=$((trackcounter+1))
				if [ "$verbosity" = "1" ]; then
					echo "Converting ${src} to ${target}"
				fi
				rsync -ab "${src}" "${target}"
				;;
				
				*)
				echo "No match found, ignoring file $src"

			esac
		done

		echo " "
		echo Coverted soundfont saved in "${targetpath}"
		echo " "
	done

	echo " "
	echo " "
	echo "Soundfont conversion complete."
	echo "  If you see files with a '~' at the end, this file already existed in the output folder"
	echo "  before the conversion and was renamed to avoid accidental overwriting."
	echo " "
	echo " --- MTFBWY ---"

else
	echo "Invalid conversion choice, please run the tool again."
	echo " "
	echo " "
fi
