%Frere Jacque
local
   %2 1er mesure, ce sonte des elements de partition
   Mesure1= transpose(semitones:1 [b4 c#5 d#5 b4])
   Mesure3= stretch(factor:1.0  [e5 f5 stretch(factor:2.0 [g5])])
   Mesure5=  stretch(factor:0.5 [g5 a5 g5 f5])
   Mesure5b= stretch(factor:1.0 [e5 c5])
   Mesure7= stretch(factor:1.0  [  c5 [c4 g4] stretch(factor:2.0 [c5])  ]    )
   %est une partition
   MDroite=[   duration(seconds:10.0 [Mesure1 Mesure1 Mesure3 Mesure3 Mesure5 Mesure5b Mesure5 Mesure5b Mesure7 Mesure7])  ]
   %est une musique
   MusicMDroite= [partition(MDroite)]
   MusicMDroiteE=[echo(delay:2.5 decay:0.2 1:MusicMDroite)] 
   %Main Gauche
   %partition
   MGauche= [duration(seconds:1.15 [c4 g4 e4 g4 c4 g4 e4 g4])]
   MusicMGauche=[repeat(amount:8  [partition(MGauche)] )]
   %Somme des 2 Mains
   Somme=[merge( [1.0#MusicMDroiteE 0.5#MusicMGauche] )]
     %couper a 10 sec
   Loop=[loop(duration:10.0 1:Somme)]
in
   Loop
end

   