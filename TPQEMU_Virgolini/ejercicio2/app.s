
//general settings
.equ SCREEN_WIDTH, 		640
.equ SCREEN_HEIGH, 		480
.equ BITS_PER_PIXEL,  	32
.equ DELAY, 			1999

//pipe settings
.equ PIPE_WIDTH,		60	//Ancho del pipe en pixeles
.equ PIPE_GAP,			80	//Tamaño del gap
.equ PIPE_HEAD_WIDTH,	5  	//"voladizo" del pipie head
.equ PIPE_HEAD_HEIGH,	25	//Altura del pipe head
.equ PIPE_BORDERS,		3	//Ancho de los bordes del pipe

//bird settings
.equ BIRD_XPOSITION,	145 //Posicion del bird en x (siempre constante)
.equ BIRD_RADIUS,		20	//Tamaño del cuerpo del bird
.equ BIRD_MOUTH_WIDTH,	25	//Ancho del pico del bird
.equ BIRD_MOUTH_HEIGH,	12	//Altura del pico del bird

//default pipes heigh
.equ PIPE_MEDIUM_HEIGH,	175 //Altura del pipe "medio"
.equ PIPE_HIGH_HEIGH,	50 	//Altura del pipe "alto"
.equ PIPE_LOW_HEIGH,	275 //Altura del pipe "bajo"

//bird trayectory
.equ END_LOW_PIPE,		600
.equ STAY_HIGH_PIPE,	520
.equ END_HIGH_PIPE,		420
.equ STAY_MEDIUM_PIPE,	280
.equ END_MEDIUM_PIPE,	170
.equ STAY_LOW_PIPE,		70



.globl main
main:
	// X0 contiene la direccion base del framebuffer
 	mov x20, x0	// Save framebuffer base address to x20	
	//---------------- CODE HERE ------------------------------------
	
	mov x21, SCREEN_WIDTH		  //guardamos el ancho de la pantall en x20

	movz x7, #640, lsl 0

next_frame:

//Paint background:
	add x0, x20, xzr
	movz x10, 0x71, lsl 16
	movk x10, 0xc5cf, lsl 00
	mov x2, SCREEN_HEIGH         // Y Size 
background1:
	mov x1, SCREEN_WIDTH         // X Size
background0:
	stur w10,[x0]	   // Set color of pixel N
	add x0,x0,4	   // Next pixel
	sub x1,x1,1	   // decrement X counter
	cbnz x1,background0	   // If not end row jump
	sub x2,x2,1	   // Decrement Y counter

	//Cambiaremos el color dependiendo de la posicion y:
pasto:
	cmp x2, #40
	b.ne tierra
	movz x10, 0x03, lsl 16
	movk x10, 0x9e01, lsl 00
tierra:
	cmp x2, #32
	b.ne nextline
 	movz x10, 0xdf, lsl 16
	movk x10, 0xca8d, lsl 00
nextline:
	cbnz x2,background1	   // if not last row, jump

//Dibujamos las nubes
	movz x3, #280, lsl 00			//definimos x_position
	movz x4, #260, lsl 00			//definimos y_position
	bl draw_cloud					//dibujamos la nube
	
	movz x3, #50, lsl 00
	movz x4, #125, lsl 00
	bl draw_cloud
	
	movz x3, #450, lsl 00
	movz x4, #150, lsl 00
	bl draw_cloud

//Una vez terminado el background dibujaremos los pipes:
	sub x3, x7, #525
	movz x4, PIPE_LOW_HEIGH				//definimos la altura del pipe
	bl draw_pipe						//dibujamos el pipe

	sub x3, x7, #350
	movz x4, PIPE_HIGH_HEIGH
	bl draw_pipe

	sub x3, x7, #110
	movz x4, PIPE_MEDIUM_HEIGH
	bl draw_pipe

//Ahora dibujaremos el pajarito

	//dependiendo del frame debe subir bajar o quedarse en el lugar

	cmp x7, END_LOW_PIPE //Hasta que se cumpla END_MEDIUM_PIPE, hacer stay_low
	b.ge stay_low
	cmp x7, STAY_HIGH_PIPE  //Hasta que se cumpla STAY_HIGH_PIPE, hacer go_high
	b.ge go_high
	cmp x7, END_HIGH_PIPE  //Hasta que se cumpla END_HIGH_PIPE, hacer stay_high
	b.ge stay_high
	cmp x7, STAY_MEDIUM_PIPE  //Hasta que se cumpla STAY_MEDIUM_PIPE, hacer go_medium
	b.ge go_medium
	cmp x7, END_MEDIUM_PIPE  //Hasta que se cumpla END_MEDIUM_PIPE, hacer stay_medium
	b.ge stay_medium
	cmp x7, STAY_LOW_PIPE
	b.ge go_low



stay_low:
	movz x4, #350, lsl 00
	b place_bird

go_high:
	movz x5, #3, lsl 00		//salto de frame a frame
	sub x4, x7, END_LOW_PIPE
	mul x4, x4, x5
	add x4, x4, #350
	b place_bird
stay_high:
	movz x4, #110, lsl 00
	b place_bird
go_medium:
	movz x5, #1, lsl 00		//salto de frame a frame
	sub x4, x7, END_HIGH_PIPE
	mul x4, x4, x5
	movz x5, #110, lsl 00
	sub x4, x5, x4
	b place_bird
stay_medium:
	movz x4, #250, lsl 00
	b place_bird
go_low:
	movz x5, #1, lsl 00		//salto de frame a frame
	sub x4, x7, END_MEDIUM_PIPE
	mul x4, x4, x5
	movz x5, #250, lsl 00
	sub x4, x5, x4
	b place_bird

place_bird:
	bl draw_bird


//hacemos un delay hasta mostrar el siguiente frame
	mov x23, DELAY
	mul x23, x23, x23
delay:
	sub x23, x23, #1
	cbnz x23, delay

//next frame
	cbnz x7, not_end_frame
	movz x7, #641, lsl 0
not_end_frame:
	sub x7, x7, #1
	b next_frame



//-----------------------------Funciones-----------------------------

//-----Funcion para dibujar pipes-----
draw_pipe:
	//"Parametros:"
	//X3 = x_position
	//x4 = y_position


//Primero dibujamos "los bordes" del pipe

	//Color del borde
	movz x10, 0x0000, lsl 00

	//direccion donde empezaremos a dibujar (x_position * 4 + direccion_de_inicio)
	lsl x9, x3, #2
	add x9, x9, x20

	//limite inferior (guardamos en x15 la direccion donde "empieza" el pasto,
					 //luego la compararemos con la direccion donde estamos "dibujando")
	movz x15, #440, lsl 00
	mul x15, x15, x21
	lsl x15, x15, #2
	add x15, x15, x20

	//contador, altura del gap (tanto limite_superior-comienzo_de_gap, como comienzo_de_gap-fin_de_gap )
	add x12, x4, xzr

	//dibujamos los bordes
pipe_row_border:
	mov x11, PIPE_WIDTH
pipe_fill_row_border:
	stur w10,[x9]
	add x9,x9,4
	sub x11,x11,1
	cbnz x11, pipe_fill_row_border
	add x11, x11, x21
	sub x11, x11, PIPE_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11				//bajamos a la siguiente linea
	
	sub x12, x12, #1
	cbnz x12, not_gap_border		//checkeamos si debemos hacer el gap

	//draw top pipe head
	mov x11, PIPE_HEAD_WIDTH
	lsl x11, x11, #2
	sub x9, x9, x11
	mov x14, PIPE_HEAD_HEIGH
	pipe_head_row0_border:
	mov x13, PIPE_HEAD_WIDTH
	lsl x13, x13, #1
	add x13, x13, PIPE_WIDTH
	pipe_head_fill_row0_border:
	stur w10, [x9]
	add x9, x9, #4
	sub x13, x13, #1
	cbnz x13, pipe_head_fill_row0_border
	add x11, x21, xzr
	sub x11, x11, PIPE_HEAD_WIDTH
	sub x11, x11, PIPE_HEAD_WIDTH
	sub x11, x11, PIPE_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11
	sub x14, x14, #1
	cbnz x14, pipe_head_row0_border

	//make gap
	mov x12, PIPE_GAP
gap_row_border:
	cbz x12, pipe_head_border
	add x9, x9, #2560		//Bajamos una linea sin dibujar nada
	sub x12, x12, #1
	b gap_row_border

	//draw bottom pipe head
pipe_head_border:
	mov x14, PIPE_HEAD_HEIGH
	pipe_head_row1_border:
	mov x13, PIPE_HEAD_WIDTH
	lsl x13, x13, #1
	add x13, x13, PIPE_WIDTH
	pipe_head_fill_row1_border:
	stur w10, [x9]
	add x9, x9, #4
	sub x13, x13, #1
	cbnz x13, pipe_head_fill_row1_border
	add x11, x21, xzr
	sub x11, x11, PIPE_HEAD_WIDTH
	sub x11, x11, PIPE_HEAD_WIDTH
	sub x11, x11, PIPE_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11
	sub x14, x14, #1
	cbnz x14, pipe_head_row1_border

	mov x11, PIPE_HEAD_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11

not_gap_border:
	cmp x15, x9
	b.hi pipe_row_border



//Ahora dibujamos el "relleno" del pipe (es casi identico al codigo anterior,
										//solo debemos hacer algunos ajustes para que se vea el borde) 

	//Color del pipe
	movz x10, 0x73, lsl 16
	movk x10, 0xbc2d, lsl 00

	//direccion donde empezaremos a dibujar
	add x9, x3, PIPE_BORDERS
	lsl x9, x9, #2
	add x9, x9, x20

	//limite inferior
	movz x15, #440, lsl 00
	mul x15, x15, x21
	lsl x15, x15, #2
	add x15, x15, x20

	//contador, altura del gap
	add x12, x4, xzr
	add x12, x12, PIPE_BORDERS

	//draw actual pipe
pipe_row_fill:
	mov x11, PIPE_WIDTH
	sub x11, x11, PIPE_BORDERS
	sub x11, x11, PIPE_BORDERS
pipe_fill_row_fill:
	stur w10,[x9]
	add x9,x9,4
	sub x11,x11,1
	cbnz x11, pipe_fill_row_fill
	add x11, x11, x21
	sub x11, x11, PIPE_WIDTH
	add x11, x11, PIPE_BORDERS
	add x11, x11, PIPE_BORDERS
	lsl x11, x11, #2
	add x9, x9, x11				//bajamos a la siguiente linea
	
	sub x12, x12, #1
	cbnz x12, not_gap_fill		//checkeamos si debemos hacer el gap

	//draw top pipe head
	mov x11, PIPE_HEAD_WIDTH
	lsl x11, x11, #2
	sub x9, x9, x11
	mov x14, PIPE_HEAD_HEIGH
	sub x14, x14, PIPE_BORDERS
	sub x14, x14, PIPE_BORDERS
	pipe_head_row0_fill:
	mov x13, PIPE_HEAD_WIDTH
	lsl x13, x13, #1
	add x13, x13, PIPE_WIDTH
	sub x13, x13, PIPE_BORDERS
	sub x13, x13, PIPE_BORDERS
	pipe_head_fill_row0_fill:
	stur w10, [x9]
	add x9, x9, #4
	sub x13, x13, #1
	cbnz x13, pipe_head_fill_row0_fill
	add x11, x21, xzr
	sub x11, x11, PIPE_HEAD_WIDTH
	sub x11, x11, PIPE_HEAD_WIDTH
	add x11, x11, PIPE_BORDERS
	add x11, x11, PIPE_BORDERS
	sub x11, x11, PIPE_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11
	sub x14, x14, #1
	cbnz x14, pipe_head_row0_fill

	//make gap
	mov x12, PIPE_GAP
	add x12, x12, PIPE_BORDERS
	add x12, x12, PIPE_BORDERS
gap_row_fill:
	cbz x12, pipe_head_fill
	add x9, x9, #2560		//Bajamos una linea sin dibujar nada
	sub x12, x12, #1
	b gap_row_fill

	//draw bottom pipe head
pipe_head_fill:
	mov x14, PIPE_HEAD_HEIGH
	sub x14, x14, PIPE_BORDERS
	sub x14, x14, PIPE_BORDERS
	pipe_head_row1_fill:
	mov x13, PIPE_HEAD_WIDTH
	lsl x13, x13, #1
	add x13, x13, PIPE_WIDTH
	sub x13, x13, PIPE_BORDERS
	sub x13, x13, PIPE_BORDERS
	pipe_head_fill_row1_fill:
	stur w10, [x9]
	add x9, x9, #4
	sub x13, x13, #1
	cbnz x13, pipe_head_fill_row1_fill
	add x11, x21, xzr
	sub x11, x11, PIPE_HEAD_WIDTH
	sub x11, x11, PIPE_HEAD_WIDTH
	add x11, x11, PIPE_BORDERS
	add x11, x11, PIPE_BORDERS
	sub x11, x11, PIPE_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11
	sub x14, x14, #1
	cbnz x14, pipe_head_row1_fill

	mov x11, PIPE_HEAD_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11

not_gap_fill:
	cmp x15, x9
	b.hi pipe_row_fill


	br x30


//------Funcion para dibujar circulos-----
draw_circle:
	//"Parametros:"
	//x3 = x_center
	//x4 = y_center
	//x5 = radius
	//x6 = colour 

	//Color de circulo
	add x10, x6, xzr

	//Haremos un cuadrado de lado r que contendrá el circulo, y pondremos a x9 un vertice del cuadrado
	sub x9, x4, x5
	mul x9, x9, x21
	add x9, x9, x3
	sub x9, x9, x5
	lsl x9, x9, #2
	add x9, x9, x20

	//colocamos en x13 el cuadrado del radio (r²) para luego compararlo
	mul x13, x5, x5

	//recorremos el cuadrado
	add x11, x5, x5
	circle_row:
	add x12, x5, x5
	circle_fill_row:
	//checkear si debemos pintarlo o no mediante la formula (x-x0)²+(y-y0)²<=r²
	sub x14, x3, x5
	add x14, x14, x12
	sub x14, x14, x3
	mul x14, x14, x14
	sub x15, x4, x5
	add x15, x15, x11
	sub x15, x15, x4
	mul x15, x15, x15
	add x14, x14, x15
	cmp x13, x14
	b.lo circle_not_paint	//si la distancia del pixel al centro es menor al radio, debemos pintar el pixel, de lo contrario no
	stur w10, [x9]
	circle_not_paint:
	add x9, x9, #4
	sub x12, x12, #1
	cbnz x12, circle_fill_row
	sub x12, x21, x5
	sub x12, x12, x5
	lsl x12, x12, #2
	add x9, x9, x12
	sub x11, x11, #1
	cbnz x11, circle_row

	br x30

//-----Funcion para dibujar nubes-----
draw_cloud:
	//"Parametros:"
	//x3 = x_position
	//x4 = y_position

	/*
	Crearemos una nube haciendo tres filas de circulos
	la fila central sera mas larga que las demas, y sera los extremos de la nube
	una vez hecha la fila central, dibujaremos circulos por encima y por debajo de esta
	*/

	//store return position in register x20
	/*
	como vamos a utilizar la funcion para hacer circulos, debemos guardar la rireccion para volver a main
	*/
	add x22, x30, xzr

	//set radius
	movz x5, #25, lsl 00

	//set colour
	movz x6, 0xFFFF, lsl 16
	movk x6, 0xFFFF, lsl 00

	//center row
	bl draw_circle
	add x3, x3, 45
	bl draw_circle
	add x3, x3, 45
	bl draw_circle
	add x3, x3, 45
	bl draw_circle
	//lower row
	sub x3, x3, 25
	add x4, x4, 25
	bl draw_circle
	sub x3, x3, 40
	bl draw_circle
	sub x3, x3, 40
	bl draw_circle
	//upper row
	sub x4, x4, 50
	bl draw_circle
	add x3, x3, 40
	bl draw_circle
	add x3, x3, 40
	bl draw_circle

	br x22

//-----funcion para dibujar un pajarito-----
draw_bird:
	//"Parametros:"
	//x4 = y_position

	//store return position in register x20
	add x22, x30, xzr

	//set x_position
	mov x3, BIRD_XPOSITION

	//set border colour
	movz x6, 0x0000, lsl 00

	//set radius
	mov x5, BIRD_RADIUS

	//draw "borders of the bird"
	bl draw_circle

	//set colour of the bird
	movz x6, 0xf7, lsl 16
	movk x6, 0xdf00, lsl 0

	//fill the bird
	sub x5, x5, #2
	bl draw_circle

	//draw the eye
	add x3, x3, #12
	sub x4, x4, #9
	movz x5, #11, lsl 00
	movz x6, 0x0000, lsl 00
	bl draw_circle					//borde del ojo
	movz x5, #9, lsl 00
	movz x6, 0xffff, lsl 16	
	movk x6, 0xffff, lsl 0
	bl draw_circle					//relleno del ojo
	add x3, x3, #3
	movz x5, #3, lsl 00
	movz x6, 0x0000, lsl 0
	bl draw_circle					//pupila del ojo


	//draw the wing
	sub x3, x3, #28
	add x4, x4, #14
	movz x5, #12, lsl 00		
	movz x6, 0x0000, lsl 0
	bl draw_circle					//borde del ala
	movz x5, #10, lsl 00		
	movz x6, 0xf7, lsl 16	
	movk x6, 0xf794, lsl 0
	bl draw_circle					//relleno del ala

	//draw the mouth
	//borders
	sub x9, x4, #3
	mul x9, x9, x21
	add x9, x9, x3
	add x9, x9, #17
	lsl x9, x9, #2
	add x9, x9, x20
	movz x6, 0x0000, lsl 0
	mov x10, BIRD_MOUTH_HEIGH
	bird_mouth_row0:
	mov x11, BIRD_MOUTH_WIDTH
	bird_mouth_fill_row0:
	stur w6, [x9]
	add x9, x9, #4
	sub x11, x11, #1
	cbnz x11, bird_mouth_fill_row0
	add x11, x21, xzr
	sub x11, x11, BIRD_MOUTH_WIDTH
	lsl x11, x11, #2
	add x9, x9, x11
	sub x10, x10, #1
	cbnz x10, bird_mouth_row0
	//actual mouth
	movz x6, 0xf7, lsl 16		
	movk x6, 0x5421, lsl 0
	sub x9, x4, #1
	mul x9, x9, x21
	add x9, x9, x3
	add x9, x9, #19
	lsl x9, x9, #2
	add x9, x9, x20
	mov x10, BIRD_MOUTH_HEIGH
	sub x10, x10, #4
	bird_mouth_row1:
	mov x11, BIRD_MOUTH_WIDTH
	sub x11, x11, #4
	bird_mouth_fill_row1:
	stur w6, [x9]
	add x9, x9, #4
	sub x11, x11, #1
	cbnz x11, bird_mouth_fill_row1
	add x11, x21, xzr
	sub x11, x11, BIRD_MOUTH_WIDTH
	add x11, x11, #4
	lsl x11, x11, #2
	add x9, x9, x11
	sub x10, x10, #1
	cbnz x10, bird_mouth_row1
	//lips
	movz x6, 0x0000, lsl 16		
	movk x6, 0x0000, lsl 0
	add x9, x4, #3
	mul x9, x9, x21
	add x9, x9, x3
	add x9, x9, #22
	lsl x9, x9, #2
	add x9, x9, x20
	movz x10, #2, lsl 00
	bird_mouth_row2:
	movz x11, #20, lsl 00
	bird_mouth_fill_row2:
	stur w6, [x9]
	add x9, x9, #4
	sub x11, x11, #1
	cbnz x11, bird_mouth_fill_row2
	add x11, x21, xzr
	sub x11, x11, #20
	lsl x11, x11, #2
	add x9, x9, x11
	sub x10, x10, #1
	cbnz x10, bird_mouth_row2
	

	br x22
