%Nom: Corentin Denis        NOMA:58701700
%     Dinh Thanh Phong Do   NOMA:13601700
%
local
   [Project] = {Link ['Project2018.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%@Specification:
%Arg: Note/Silence
%Return: ExtendedNote
   fun {NoteToExtended Note}
      case Note
      of Name#Octave then % Si la gramaire de la note est du genre: a#4 
	 note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] Atom then% Si la grammaire de la note est du genre: a ou a5 ou silence
	 case {AtomToString Atom}
	 of [_] then % cas ou la note est du genre: a
	    note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
	 [] [N O] then% cas ou la note est du genre: a5
	    note(name:{StringToAtom [N]}
		 octave:{StringToInt [O]}
		 sharp:false
		 duration:1.0
		 instrument: none)
	 [] [S I L E N C E] then %cas ou la note est du genre: silence
	    silence(duration:1.0)
	 end
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Chord (Liste de notes)
   %Return: ExtendedChord
   %Transforme Chord en ExtendedChord
   
   fun{ChordToExtended Chord}
      case Chord of nil then nil
      [] H|T then
	 {NoteToExtended H}|{ChordToExtended T}
      end    
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Note/Chord ExtendedNote/ExtendedChord
   %Return: ExtendedNote/ExtendedChord
   %Transforme Note/Chord en ExtendedNote/ ExtendedChord
   
   fun{Extended PartitionItem}
      case PartitionItem of nil then nil
      %Traitons les cas ou PartitionItem est une ExtendedNote
      [] note(name:N octave:O sharp:B duration:D instrument:I)then%
	 PartitionItem
      [] silence(duration:D) then
	 PartitionItem
      %Traitons le cas ou PartitionItem est un Chord ou un ExtendedChord
      [] H|T then
	 {Extended H}|{Extended T}
      else
      %Traitons le cas ou PartitionItem est une Note
	 {NoteToExtended PartitionItem}
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Note/Chord, Amount(Integer)
   %Transformation :Renvoie une liste avec <amount> fois la repetition de Extended Note/Chord
   %Ce qui implique que l'on modifie Note/Chord vers Extended Note/Chord
   fun{Drone  Amount Note}
      if Amount==0 then nil
      else
      %Traitons quand Note est un Chord (Liste de Notes)
	 case Note of nil then nil
	 [] H|T then
	    {ChordToExtended Note}|{Drone Amount-1 Note}
	 else
	 %Traitons quand Note est une Note
	    {NoteToExtended Note}|{Drone Amount-1 Note}
	 end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Duree (Duree souhaite)(Float),FlatPartition
   %Return: Flatpartition
   %Retourne une FlatPartition dont la somme des duration des loop
   fun{Duration FlatPartition Duree}
      local
	 CurrentDuration%Stocke la duree initiale de Partition

         %@Spe
         %Arg: FlatPartition et Acc=0
         %Return:Effectue la Somme des durees des notes
	 fun{SumOfNote FlatPartition Acc}
	    case FlatPartition of nil then Acc
	    [] H|T then
               % Extended Chord ou Extended Note
	       case H of L|R then
	       %Extended Chord: on additionne la duree de la 1er
	       %Note car toute les Notes ont la meme duree
		  {SumOfNote T Acc+L.duration}
	       else
               %ExtendedNote
		  {SumOfNote T Acc+H.duration}
	       end
	    end
	 end
      in	 
	 CurrentDuration = {SumOfNote FlatPartition 0.0}%Duree totale initiale	 
	 {Stretch Duree/CurrentDuration FlatPartition}
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%@Specification
%Arg: ExtendedNote
%Return:Renvoie un numero pour chaque note, suivant ce principe:
%      silence=0  a1= 1  a#1=2 b1=3 .... a2=13
   fun{NoteToNumber ExtendedNote}
      local
	 X Y Z 
	 Note=note(1:1 2:3 3:4 4:6 5:8 6:9 7:11)%Constante qui donne le numero de la note
                                                %a1=1 (a#1=2) b1=3 c2=4...
	 
      in
      
	 case ExtendedNote of silence(duration:D) then
         %Traitons le cas des silences
	    0
	 else
         %Traitons le cas des ExtendedNote
	    X={AtomToString ExtendedNote.name}
            %X est un tableau du genre [_] avec des valeurs entieres. a=97 b=98...
	    case X of H|T then
	    %H est la valeur contenu dans le tableau X
	    %On Modifie cette valeur pour retourner ce qui est mentionne
	    %en specification. On stocke cette valeur dans la variable Z
	       Y= H-96 %a=1, b=2, c=3, d=4, e=5, f=6, g=7
	       if ExtendedNote.sharp==true then
	       % pour les Notes avec des dieses tel que: a#
	       % on doit retourner la valeur de la note+1
	       % exemple: a1=1 => a#1=2
		  Z=Note.Y+1 
	       else
		  Z=Note.Y
	       end	    
	    end
	 %Ensuite On Multiplie par <octave-> pour avoir la valeur a l'octave pour les notes
	 %Correspondant
	    if (Z mod 13)<4 then  % pour les notes a , a# et b
	       Z+(ExtendedNote.octave-1) *12
	    else%pour les autres notes
	       Z+(ExtendedNote.octave-2) *12
	    end
	 end
      end
   end
   %@Specification:
   %Arg: Nombre (Entier)
   %Return:Renvoie un record avec la gramaire: note(name: octave: sharp:)
   %       Suivant toujours la meme convention utilise pour NoteToNumber
   %
   fun{NumberToNote Number}
      local
	 Notename=notename(1:a 2:a 3:b 4:c 5:c 6:d 7:d 8:e 9:f 10:f 11:g 12:g)% Le nom de chaque note dans 1 octave
	 Sharp=sharp(1:false 2:true 3:false 4:false 5:true 6:false 7:true 8:false 9:false 10:true 11:false 12:true)%verifie les dieses dans 1 octave
	 Note
	 Octave
      in
	 if Number==0 then
         %Traitons le cas du silence
	    silence(duration:1.0)
	 else	 
	 
	    Note= Number mod 12     %Donne le nom de la note
	                            %Remarquons aussi que pour le cas Number=12 (g#), Note=0, il faut traiter ce cas particulier
	    if Note==0 then
	    %Traitons le cas g#
	       Octave=Number div 12+1
	       note(name:'g' octave:Octave sharp:true)
	    else
	    %Traitons les cas generaux
	       if Note < 4 then %a a# b
		  Octave= (Number div 12)+1
		  note(name:Notename.Note octave:Octave sharp:Sharp.Note)
	       else
		  Octave=(Number div 12)+2% les cas de c jusque g
		  note(name:Notename.Note octave:Octave sharp:Sharp.Note)
	       end
	    end
	 end
      end
   end
%@Specification
%Arg: Semitone(Integer) FlatPartition
%Return:Retourne une FlatPartition, transpose de <Semitone> demi ton

   fun{Transpose Semitone FlatPartition}
      local Z in	    
	 case FlatPartition of nil then nil
	 [] H|T then	 
	    case H of L|R then
                 %Traitons les ExtendedChords: H est compose d'ExtendedNotes
    	         %Ce cas est traite ci dessous
	       {Transpose Semitone H}|{Transpose Semitone T}
	    [] silence(duration:D) then
	         %Traitons le silence
	       H|{Transpose Semitone T}
	    else
                 %ExtendedNote
	         %X={NoteToNumber H} On transforme la Note en Nombre
	         %Y=X+Semitone       Auquel on rajoute le nombre de demi ton
	         %Z={NumberToNote Y} Puis on reconverti en un enregistrement note(name: octave: boolean: )
	       Z={NumberToNote ({NoteToNumber H}+Semitone)}
	       note(name:Z.name octave:Z.octave sharp:Z.sharp duration:H.duration instrument:H.instrument)|{Transpose Semitone T}
	    end
	 end
      end
   end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%@Specification:
%Arg: Factor (Float) FlatPartition
%Return: Une FlatPartition dont la duree de chaque note a ete etire par le <Factor> indique

   fun{Stretch Factor FlatPartition}
      case FlatPartition of nil then nil
      [] H|T then
	 case H of L|R then
               %Traitons les ExtendedChords, H est une liste de ExtendedNotes qui sont traites ci dessous
	    {Stretch Factor H}|{Stretch Factor T}
	 else
               %Traitons les ExtendedNotes/Silences	       
	    local X in
	       X= H.duration*Factor% X represente la nouvelle duree de la note
	       case H of silence(duration:D) then
		  %Traitons les Silences
		  silence(duration:X)|{Stretch Factor T}
	       else
		  %Traitons les autres ExtendedNotes
		  note(name:H.name octave:H.octave sharp:H.sharp duration:X instrument:H.instrument)|{Stretch Factor T}
	       end
	    end
	 end
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: FlatPartition
   %Return:FlatPartition
   %Transforme Partition en une FlatPartition, Toutes les transformations sont geres
   fun{PartitionToTimedList Partition} 
      case Partition of nil then nil
      [] H|T then %note/chord/transformation
	 %Traitons d'abbord les Transformations:
	 case H of drone(note:N amount:A)then     
	    {Append {Drone H.amount H.note} {PartitionToTimedList T}}
	    
	 [] duration(seconds:S P) then
	    {Append {Duration {PartitionToTimedList H.1} H.seconds} {PartitionToTimedList T}}
	    
	 [] stretch(factor:F P) then
	    {Append {Stretch H.factor {PartitionToTimedList H.1}} {PartitionToTimedList T}}
	    
	 [] transpose(semitones:I P) then
	    {Append {Transpose H.semitones {PartitionToTimedList H.1}} {PartitionToTimedList T}}
	 else
	    %Traitons des Notes/Chord/ et  Extended Note/Chord
	    {Extended H}|{PartitionToTimedList T}
	 end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Matrice ou bien une Liste
   %Return: Renvoie la Matrice/Liste dont chaque element a ete
   %multiplie par le facteur
   fun{Mult Matrice Factor}
      case Matrice of nil then nil
      [] H|T then
	 case H of L|R then
	    %Traitons le cas de la Matrice= Liste de Liste
	    %qui sera traite en dessous
	    {Mult H Factor}|{Mult T Factor}    
	 else
	    %Traitons le cas de la Liste
	    H*Factor|{Mult T Factor}
	 end     
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: L1= Liste(Float), L2= Liste(Float), F1= Facteur(Float) F2=Facteur(Float)
   %Return: renvoie (F1*L1)+(F2*L2) 
   fun{SumLine L1 F1 L2 F2}
      %Traitons d'abord les cas limites quand on se trouve a la fin des listes
      if L1==nil then
	 %Traitons le cas  Longueur L1<L2
	 %Le cas L1==L2 est aussi traite car {Mult nil F2} retourne nil
	 {Mult L2 F2}
      elseif L2==nil then
	 %Traitons le cas Longueur L2<L1
	 {Mult L1 F1}
      %Traitons maintenant les cas ou nous sommes pas a la fin des listes
      else
	 case L1 of H|T then
	    case L2 of R|L then
	       %On additionne les premiers elements
	       (H*F1+R*F2)|{SumLine T F1 L F2}
	    end
	 end
      end 
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Music With Intensities:= [ factor#music factor#music]
   %Return: Somme du produit des Musiques(contenues dans MusicWithIntensities)
   %        par leur facteur respectif
   fun{Merge MWI}
      case MWI of nil then nil
      [] H|T then
	 %Traitons le Cas: Merge avec 1 seul record dans MWI
	 case T of nil then
	    {Mult {Mix P2T H.2} H.1}
	 %Traitons le Cas: Merge avec plus d'un record dans MWI
	 []L|R then
	    case R of nil then
	       %Fin de la liste de records
	       %H.2=Music L.2=Music H.1=Facteur L.1=Facteur
	       {SumLine {Mix P2T H.2} H.1 {Mix P2T L.2} L.1}	 
	    else
	       {Merge [H 1.0#{Merge T}]}
	    end
	 end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: DelayFloat=duree (float) DecayFloat=facteur (float) Samples
   %Return: Somme du produit de Music concatene du silence (delayfloat)
   %        par le facteur (decayfloat), et du Samples
   fun{Echo DelayFloat DecayFloat Samples}
      local
	 Delay
	 SampleWithSilence
	 %@Specification:
	 %Arg: NumberInt(Integer)
	 %Return: Samples
	 %Cette fonction renvoie une liste du genre 0.0|0.0|....|Samples|nil
	 %Le nombre de 0 est determine par NumberInit
	 fun {DelaySample NumberInt Samples}
	    if NumberInt==0 then Samples
	    else	       
	       0.0|{DelaySample NumberInt-1 Samples}
	    end
	 end     	 	 
      in
	 %Nbre d'echantillon necessaire pour effectuer un silence de duree DelayFloat:
	 Delay={FloatToInt 44100.0*DelayFloat}
	 
	 SampleWithSilence={DelaySample Delay Samples}
	 %Voir specification SumLine ci dessus
	 {SumLine Samples 1.0 SampleWithSilence DecayFloat}
         
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg:FlatPartition Boolean(pour l'extension)
   %Return: Transforme une FlatPartition en un Samples. Est compose de 2 sous fonctions:
   %        NoteToSamples et SumChord, dont les specifications sont ci dessous
   fun{PartitionToSamples FlatPartition Boolean}
      local
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	 %@Specification:
	 %Arg:ExtendedNote
	 %Return:Samples
	 %Transforme une Note en un Samples
	 fun{NoteToSample ExtendedNote}%note(name: octave: sharp: duration: instrument:)
	    local
	       DeltaSemitone
	       Frequence
	       PI=3.141592
	       NumberOfE
	       fun{NoteToSample2 ExtendedNote NumberInit NumberOfE DeltaSemitone Frequence PI}
		  if NumberInit<NumberOfE then
		     %Tant qu'on a pas atteint la longueur de l'echantillon
		     case ExtendedNote of silence(duration:D) then
			0.0|{NoteToSample2 ExtendedNote NumberInit+1 NumberOfE DeltaSemitone Frequence PI}	    
		     else
			%Formule donne dans le cours pour l'echantillonage a une frequence de 44100.0 par seconde
			0.5*{Sin (2.0*PI*Frequence*{IntToFloat NumberInit}/44100.0)}|
			{NoteToSample2 ExtendedNote NumberInit+1 NumberOfE DeltaSemitone Frequence PI}
		     end
		  else
		     nil
		  end
	       end
	       
	    in
	       NumberOfE={FloatToInt (ExtendedNote.duration*44100.0) }
               %NumberOfE contient le nombre d'echantillons de la note
	       
	       DeltaSemitone={NoteToNumber ExtendedNote}-37
               %Diffenrence de demi ton par rapport au La de reference

	       Frequence={Pow 2.0 {IntToFloat DeltaSemitone}/12.0}*440.0
	       %Formule dans le cous
	       {NoteToSample2 ExtendedNote 0 NumberOfE DeltaSemitone Frequence PI}
	    end
	 end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	 %@Specification:
	 %Arg: ExtendedChord
	 %Return: Samples
	 %Additionne terme a terme les Samples associes aux ExtendedeNote, donnant ainsi le Sample du Chord
	 fun{SumChord ExtendedChord}
	    local
	       fun{SumChord2 ExtendedChord Coef}
		  case ExtendedChord of nil then nil
		  [] H|T then
		     case T of nil then {NoteToSample H}%traite les cas: [[ExtendedNote]]
		     [] L|R then%[H|L|R]
			%Nous additionnons Le Sample du 1er element (H) par le 2eme (L)
			%Et nous effectuons un appel recursive sur R
			local
			   X
			in
			   X={SumLine {NoteToSample H} Coef {NoteToSample L} Coef}
			   {SumLine X Coef {SumChord2 R Coef} Coef}
			end
		     end
		  end
	       end
	       Coef
	    in
	       %Le but du coef est de ne jamais depasser 1 ou ~1 en amplitude meme en additionnant
	       %Les differents samples sachant que chaque sample a une amplitude de + ~0.5
	       Coef=1.0/{IntToFloat {Len ExtendedChord}}
	       {SumChord2 ExtendedChord Coef}		  
	    end
	 end
      in
	 case FlatPartition of nil then nil
	 [] H|T then
	    if Boolean==false then
	    %Traitons le cas ou le lissage est desactive
	       case H of L|R then
                   %Traitons les ExtendedChords, les ExtendedNotes sont traites ci dessous
		  {Append {SumChord H} {PartitionToSamples T false}}
	       else
		  %Traitons les ExtendedNotes
		  {Append {NoteToSample H}{PartitionToSamples T false}}
	       end
	    else
            %Traitons le cas ou le lissage est active
	       case H of L|R then
		  {Append {Lissage{SumChord H}} {PartitionToSamples T true}}
	       else
		  {Append {Lissage{NoteToSample H}}{PartitionToSamples T true}}
	       end
	    end
	 end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification
   %Arg: Liste
   %Return: Retourne la longueur de cette Liste
   fun{Len L}
      local
	 fun{Leng L Acc}
	    case L of nil then Acc
	    []H|T then
	       case H of L|R then
		  {Leng T Acc+{Leng H 0}}
	       else
		  {Leng T Acc+1}
	       end
	    end
	 end	 
      in
	 {Leng L 0}
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: StartFloat (Float), StopFloat (Float), Samples
   %Return: Retourne un sample tronque de <StartFloat> secondes au debut
   %        Et <FinishFloat> secondes a la fin. Si <FinishFloat> est plus long
   %        que le samples, alors, la fonction retournera des silences
   fun{Cut StartFloat FinishFloat Samples}
      local
	 Start
	 Stop
	 TotalNumber%Nombre Total d'echantillon
	 fun{Cut2 Start Finish Samples}
	    case Samples of nil then
	       %Traitons le cas ou Finish est plus long que Samples
	       if Finish \= 0 then
		  0.0|{Cut2 Start Finish-1 Samples}
	       else
		  %Quand Finish=0, on retourne la liste
		  nil
	       end
            
	    [] H|T then
	       if Start =< 0 then
		  %Traitons les cas ou on se trouve apres start
		  if Finish == 0 then
                     % si on atteint finish on la renvoie
		     nil
		  else
		     %Traitons le cas quand on est entre Start et Stop
		     H|{Cut2 0 Finish-1 T}
		  end
	       else
		  %Traitons le cas ou on se trouve avant Start,
		  {Cut2 Start-1 Finish-1 T}
	       end
	    end
	 end      
      in
	 Start = {FloatToInt 44100.0*StartFloat}
	 Stop = {FloatToInt 44100.0*FinishFloat}
	 {Cut2 Start Stop Samples}
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg:Samples
   %Return: Samples
   %        Un sample dont l'intensite augmente progressivement lors du 1er tier,
   %        et diminue progressivement lors du dernier tier
   fun{Lissage Samples}
      local Duree in
	 Duree={IntToFloat{Len Samples}}/44100.0
	 
	 {Fade Duree/3.0  2.0*Duree/3.0 Samples}
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification
   %Arg:InFloat (Float), OutFloat (Float) Samples
   %Return: Samples
   %        Un sample dont l'intensite augmente progressivement avant InFloat,
   %        et diminue progressivement apres OutFloat
   fun{Fade InFloat OutFloat Samples}
      local
	 TotalNumber
	 CoefCroissant
	 CoefDecroissant
	 In
	 Out
	 fun{Fade2D In Out Samples Number TotalNumber CoefCroissant CoefDecroissant}
	    local
	       LengSample
	    in
	       case Samples of nil then nil
	       [] H|T then
		  case H of nil then nil% Samples [nil]
		  elseif Number<In then %Debut
		     H* {IntToFloat Number}*CoefCroissant
		     |{Fade2D In Out T Number+1 TotalNumber CoefCroissant CoefDecroissant}
	    
		  elseif Number>=Out then %Fin
		     local X Y
		     in
			X={IntToFloat TotalNumber}-({IntToFloat Number}+1.0)
	               %coef decroissant={IntToFloat TotalNumber}-{IntToFloat Out}
			H*(X)*CoefDecroissant
			|{Fade2D In Out T Number+1 TotalNumber CoefCroissant CoefDecroissant}
		     end
		  else
		     H|{Fade2D In Out T Number+1 TotalNumber CoefCroissant CoefDecroissant}
		  end
	       end
	    end
	 end
      

      in
	 In = {FloatToInt 44100.0*InFloat}% Position de debut dans l'echantillon
	 Out = {FloatToInt 44100.0*OutFloat}%Position de sortie dans l'echantillon
	 TotalNumber={Len Samples}% Nombre total d'echantillon du sample
	 CoefCroissant = 1.0/{IntToFloat In}% Coef qui permet d'augmenter progressivement l'intensite
	 CoefDecroissant =1.0/({IntToFloat TotalNumber}-{IntToFloat Out})
	 {Fade2D In Out Samples 0 TotalNumber CoefCroissant CoefDecroissant}
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Low (Float) High(Float) Samples
   %Return: Samples
   %Renvoie un sample dont toutes les valeurs du Samples se trouvent entre Low et High
   fun{Clip Low High Samples}
      case Samples of nil then nil
      [] H|T then
	 if H>High then
	    %Traitons le cas ou la valeur est>High
	    High|{Clip Low High T}
	 elseif H<Low then
	    %Traitons le cas ou la valeur est <Low
	    Low|{Clip Low High T}
	 else
	    %Traitons le cas ou la valeur est entre Low et High
	    H|{Clip Low High T}
	 end	    
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification
   %Arg: Amount(Integer) Samples
   %Return: Samples
   %Retourne un Sample qui correspond a la concatenation de Amout fois le Sample de depart
   fun{Repeat Amount Samples}
      case Samples of nil then nil
      [] H|T then
	 if Amount == 0 then nil
	 else
	    {Append Samples {Repeat Amount-1 Samples}}
	 end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification
   %Arg:Samples
   %Return: Samples
   %        Retourne le Samples de depart renverse
   fun{Reverse Samples}
      {List.reverse Samples}
   end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %@Specification:
   %Arg: Duration (Float) Samples
   %Return:Sample
   %       Joue la musique le nombre de sample indique
   fun{Loop Duration Samples}
      local
	 NSample
	 DurationMusic
	 Nloop	    
      in
	 case Samples of nil then nil
	 [] H|T then
	    NSample = {Len Samples}%Donne le nbre d'echantillon de music(int)
	    DurationMusic = {IntToFloat NSample}/44100.0 %duree de la musique en secondes (float)
	    Nloop = {FloatToInt {Floor Duration/DurationMusic}}
	    %Donne le nombre de fois que la musique doit etre repete.

	    %La formule ci dessous nous donne le temps(sec) a laquelle il faudra tronquer
	    %Duration-({IntToFloat Nloop}*DurationMusic
	    {Append {Repeat Nloop Samples} {Cut 0.0 (Duration-({IntToFloat Nloop}*DurationMusic)) Samples}}
	 end
      end
   end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   fun {Mix P2T Music}
      
      case Music of nil then nil
      [] H|T then
	 case H of samples(1:S) then
	    H.1
	 [] partition(1:P) then
	    {Append {PartitionToSamples {P2T H.1} false} {Mix P2T T}}
	 []  wave(1:F) then
	    {Append {Project.readFile H.1} {Mix P2T T}}
	 [] merge(1:MWI) then
	    {Append {Merge H.1} {Mix P2T T}}
	 %Filtres
	 [] reverse(1:M) then
	    {Append {Reverse {Mix P2T H.1}} {Mix P2T T}}
	 [] repeat(amount:A 1:M) then
	    {Append {Repeat H.amount {Mix P2T H.1}} {Mix P2T T}}
	 [] loop(duration:D 1:M)then
	    {Append {Loop H.duration {Mix P2T H.1}} {Mix P2T T}}
	 [] clip(low:L high:X 1:M) then
	    {Append {Clip H.low H.high {Mix P2T H.1}} {Mix P2T T}}
	 [] echo(delay:D decay:E 1:M) then
	    {Append {Echo H.delay H.decay {Mix P2T H.1}} {Mix P2T T}}
	 [] fade(start:S out:O 1:M) then
	    {Append {Fade H.start H.out {Mix P2T H.1}} {Mix P2T T}}
	 [] cut(start:S finish:F 1:M) then
	    {Append {Cut H.start H.finish {Mix P2T H.1}} {Mix P2T T}}
	 end	    
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music ={Project.load 'example.dj.oz'}
   %Music= {Projetct.load 'creation.dj.oz'}
   Start
   P2T=PartitionToTimedList
     

   % Uncomment next line to insert your tests.
   % \insert 'tests.oz'
   % !!! Remove this before submitting.
in
   Start = {Time}
   %{Browse {NoteToNumber {Extended a4}}}
   %{Browse {Mix P2T Music}}
   % Uncomment next line to run your tests.
   % {Test Mix PartitionToTimedList}
   %{Browse {PartitionToTimedList [transpose(1:[c e g] semitones:3)]}}
   % Add variables to this list to avoid "local variable used only once"
   % warnings.
   %%{ForAll [NoteToExtended Music] Wait}
   
   % Calls your code, prints the result and outputs the result to `out.wav`.
   % You don't need to modify this.
   {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
   
   % Shows the total time to run your code.
   {Browse {IntToFloat {Time}-Start} / 1000.0}
end
