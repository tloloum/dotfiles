# Edit text 

- 'A' -> insert fin de ligne
- 'a' -> insert après curseur
- 'i' -> insert avant curseur
- 'p / P' -> paste after / before cursor
- 'r' -> replace caractère
- 'R' -> replace + de caractère (until esc)
- 'P' -> paste *avant* curseur ('p' *après*)
- ':s/word/sub' -> change first occurence of word into sub
- ':s/word/sub/g' -> change "" in the line
- '%s/word/sub/g' -> ""       whole file

# Moving
- 'C-o' -> go back where u were
- 'w' -> mot suivant, premier caractère
- 'e' -> mot suivant, dernier caractère
- {count}G -> goto line {count}
- 'n / N' -> next occurence after /
- '%' -> matching () {} [] 
- **'o'** -> open up a line below the cursor + insert MODE ('O' au dessus)
- '.' -> repeat last command

# Motion
- 'd' -> delete operator
- 'gu / gU' -> make lowercase / uppercase operator
- ' < / > ' -> shift operator
- 'c' change operator
- 'y' yank operator (copy), ex : 'ym' = one word
	- '$' -> jusqu'a fin de ligne, avec dernier carac
	- 'e' -> end current word, avec dernier caractère (curseur jusqu'a fin du mot)
	- 'w' -> current word, sans premier caractère
	- 'j' -> ligne actuel + ligne au dessous
	- 'k' -> ligne actuel + dessus
	- 'h/l' -> caractère gauche/droite
- 'x' -> suppr caractère (= suppr)

