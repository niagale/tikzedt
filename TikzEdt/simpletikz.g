grammar simpletikz;


options 
{
	output=AST;
	language = 'CSharp2';
	//backtrack=true;
}


tokens {
	BEGIN	 	= '\\begin';	//todooooo
	END 		= '\\end';    //todooooo
	//BEGINTP	 	= '\\begin{tikzpicture}';
	//ENDTP 		= '\\end{tikzpicture}';
	//BEGINSCOPE	= '\\begin{scope}';
	//ENDSCOPE 	= '\\end{scope}';
	//TIKZPICTURE	= 'tikzpicture';	
	//SCOPE		= 'scope';
	
	USETIKZLIB	= '\\usetikzlibrary';
	TIKZSTYLE	= '\\tikzstyle';
	TIKZSET		= '\\tikzset';
	NODE		= '\\node';
	DRAW		= '\\draw';
	PATH		= '\\path';
	FILL		= '\\fill';
	LPAR		= '(';
	RPAR		= ')';
	LBR		= '[';
	RBR		= ']';
	LBRR		= '{';
	RBRR		= '}';
	KOMMA		= ',';
	//SCALE		= 'scale';
	EQU		= '=';
	SEMIC		= ';';
	COLON		= ':';
	//BACKSLASH	= '\\'; // blame antlr
	//STYLESEP	= '/.style';
	//AT		= 'at';
	//LABEL		= 'label';
	//EVERYLOOP	= 'every loop';
	
	// styles
	//ST_INNERSEP	= 'inner sep';
	//ST_OUTERSEP	= 'outer sep';
	//ST_FILL		= 'fill';
	//ST_DRAW		= 'draw';
	//ST_SHAPE	= 'shape';
	//ST_MINSIZE	= 'minimum size';
	//ST_LINEWIDTH	= 'line width';
	//ST_DASHSTYLE	= 'dash style';
	
	// edge option
	//LOOP		= 'loop';
	//IN		= 'in';
	//OUT		= 'out';
	
	// units
	//UN_PTS		= 'pt';
	//UN_CM		= 'cm';
//	UN_IN		= 'in';

// imaginary
IM_PATH;
IM_NODE;
IM_COORD;
IM_NODENAME;
IM_NUMBERUNIT;
IM_PICTURE;
IM_DOCUMENT;
IM_SCOPE;
IM_STARTTAG;
IM_ENDTAG;
IM_OPTIONS;
IM_OPTION_STYLE;
IM_OPTION_KV; 	// key or key value pair
IM_ID;
IM_TIKZSET;
IM_USETIKZLIB;
IM_STRING;
IM_STYLE;
}


tikzdocument
	:	 (dontcare_preamble | tikz_styleorset | otherbegin)*  tikzpicture  		-> ^(IM_DOCUMENT tikz_styleorset* tikzpicture)
	;

tikz_styleorset
	:	tikz_style | tikz_set
	;

dontcare_preamble
	:	~(BEGIN | TIKZSTYLE | TIKZSET)
	;
otherbegin
	:	BEGIN LBRR idd RBRR
	;

tikz_style
	:	TIKZSTYLE LBRR idd RBRR '=' tikz_options -> ^(IM_STYLE idd tikz_options)
	;

tikz_options
	: 	squarebr_start (option (',' option)* ','?)? squarebr_end		-> ^(IM_OPTIONS squarebr_start option* squarebr_end)
	;

option
	:	option_style 		
		| option_kv		
	;
	
option_kv
	:	idd ('=' iddornumberunitorstring )? -> ^(IM_OPTION_KV idd iddornumberunitorstring?)  
	;
	
tikzstring
	:	LBRR no_rlbrace* (tikzstring no_rlbrace*)* RBRR -> ^(IM_STRING LBRR RBRR ) //todo
	;

no_rlbrace
	:	~(LBRR | RBRR)
	;
iddornumberunitorstring
	:	idd | numberunit | tikzstring
	;
option_style
	:	idd '/.style' '=' LBRR (option_kv (',' option_kv)*)?  ','? RBRR  -> ^(IM_OPTION_STYLE idd option_kv*)  // '{' option '}' todo: optional ,
	;

// id composed of more than one word
idd
	:	ID (ID)*	-> ^(IM_ID ID*)
	;

numberunit
	:	number unit? -> ^(IM_NUMBERUNIT number unit?) /// check
	;
number
	:	(FLOAT | INT)
	;
unit
	:	'cm' | 'in' | 'ex' | 'mm' | 'pt'
	;
			
tikz_set
	:	 tikz_set_start (option (',' option)*)? roundbr_end -> ^(IM_TIKZSET tikz_set_start option* roundbr_end)
	;

// *** Things that go within the picture ****

tikzpicture 
	:	 tikzpicture_start tikz_options? tikzbody? tikzpicture_end		-> ^(IM_PICTURE tikzpicture_start tikz_options? tikzbody? tikzpicture_end)
	;

tikzbody
	:	( tikzscope | tikzpath | tikznodee | dontcare_body_nobr | tikz_set | tikz_style | otherbegin |otherend )  // necessary to prevent conflict with options
		( tikzscope | tikzpath | tikznodee | dontcare_body | tikz_set | tikz_style | otherbegin |otherend )*
	;
	
dontcare_body_nobr
	:	(~ (BEGIN | END | NODE | DRAW | PATH | FILL | TIKZSTYLE | TIKZSET | LBR))	// necessary to prevent conflict with options
	;	
dontcare_body
	:	(~ (BEGIN | END | NODE | DRAW | PATH | FILL | TIKZSTYLE | TIKZSET ))
	;
otherend
	:	END '{' idd '}'
	;
	
tikzpath 
	:	path_start tikz_options? tikzpathi semicolon_end	-> ^(IM_PATH path_start tikz_options? tikzpathi semicolon_end )
	;
	
tikzpathi
	:	 coordornode (coordornode | tikz_options? edgeop! coordornode )* 
	;
	
tikzscope
	:	tikzscope_start tikz_options? tikzbody? tikzscope_end		-> ^(IM_SCOPE tikzscope_start tikz_options? tikzbody tikzscope_end)
	;

coordornode
	:	coord | tikznodei
	;
	
tikznodei
	:	'node'! tikznode
	;
	
nodename
	:	LPAR id=ID RPAR		-> ^(IM_NODENAME $id)
	;

coord	
	:	  nodename 								-> ^(IM_COORD nodename)
		| ( coord_modifier? lc=LPAR numberunit KOMMA numberunit RPAR)		-> ^(IM_COORD[$lc] coord_modifier? numberunit+ )
	;

tikznode
	:	nodename? ('at' coord)? tikzstring		-> ^(IM_NODE nodename? coord? tikzstring)			
	;
	
edgeop	
	:	'--' | 'edge' | '->' | '|-' | '-|' | 'to' | 'grid' | 'rectangle'
	;	


coord_modifier
	:	'+' | '++'
	;

tikznodee
	:	node_start tikznode tikzpathi? semicolon_end -> ^(IM_PATH node_start tikznode tikzpathi? semicolon_end) //almost hack like this
	;
	
node_start
	:	NODE -> ^(IM_STARTTAG NODE)
	;

/*


path_end
	:	SEMIC -> ^(IM_ENDTAG SEMIC)
	;



//tikz_something
//	:	( ID | '\\' ID)+  -> 
//	;



//documentclass
//	:	'\\documentclass' ('[' (~ ']')* ']')? '{' (~'}')*  '}'
//	;


	
usetikzlib
	:	usetikzlib_start idd (',' idd)* roundbr_end -> ^(IM_USETIKZLIB usetikzlib_start idd* roundbr_end)
	;
usetikzlib_start
	:	USETIKZLIB '{' -> ^(IM_STARTTAG USETIKZLIB) // todo: check if necessary ...
	;



tikzstring
	:	'{'  (tikzstring | MATHSTRING | ID)* '}' -> ^(IM_STRING '{' '}' ) //todo
	;
*/
//tikzbody2
//	:	'hallo'
//	;

// ***** start and end tags *****
squarebr_start
	:	LBR -> ^(IM_STARTTAG LBR)
	;
squarebr_end
	:	RBR -> ^(IM_ENDTAG RBR)
	;	
semicolon_end
	:	';'	-> ^(IM_ENDTAG ';')
	;
roundbr_end
	:	'}'	-> ^(IM_ENDTAG '}')
	;
tikz_set_start
	:	TIKZSET '{'		-> ^(IM_STARTTAG ) // todo: check if suffices
	;
tikzpicture_start
	:	BEGIN '{' 'tikzpicture' '}' -> ^(IM_STARTTAG BEGIN)
	;
tikzpicture_end
	:	END '{' 'tikzpicture' '}' -> ^(IM_ENDTAG END)
	;
tikzscope_start
	:	BEGIN '{' 'scope' '}' -> ^(IM_STARTTAG BEGIN)
	;
tikzscope_end
	:	END '{' 'scope' '}' -> ^(IM_ENDTAG END)
	;
path_start 
	:	path_start_tag -> ^(IM_STARTTAG path_start_tag)
	;

path_start_tag
	:	DRAW | FILL | PATH
	;

ID  :	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_'|'.')*
    ;

INT :	'-'? '0'..'9'+
    ;

FLOAT
    :   '-'? ('0'..'9')+ '.' ('0'..'9')* EXPONENT?
    |   '-'? '.' ('0'..'9')+ EXPONENT?
    |   '-'? ('0'..'9')+ EXPONENT
    ;

COMMENT
    :   '%' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;

WS  :   ( ' '
        | '\t'
        | '\r'
        | '\n'
        ) {$channel=HIDDEN;}
    ;

fragment
EXPONENT : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

//OPTIONS :	'[' ~(']')* ']';

//STRING	:	'{' ( ESC_SEQ | ~('\\' | '}') )* '}';   /// not correct like this
MATHSTRING 
	:	'$' ( ESC_SEQ | ~('\\' | '$') )* '$';
//STRING
//    :  '"' ( ESC_SEQ | ~('\\'|'"') )* '"'
//    ;

//CHAR:  '\'' ( ESC_SEQ | ~('\''|'\\') ) '\''
//    ;



COMMAND
	: '\\' ID
	;
	
//fragment // this is a hack	
ESC_SEQ
    :   '\\' .   // ( |'\"'|'\''|'\\')
    ;



SOMETHING 
	:	. ;