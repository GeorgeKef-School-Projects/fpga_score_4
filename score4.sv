module score4 (
	input  logic clk,
	input  logic rst,

	input  logic left,
	input  logic right,
	input  logic put,
	
	output logic player,
	output logic invalid_move,
	output logic win_a,
	output logic win_b,
	output logic full_panel,

	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue	
);

// YOUR IMPLEMENTATION HERE

//Falling/Rising Edge
//left
    logic edge_reg_left,falling_edge_left,rising_edge_left;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg_left <= 1'b0;
        end else begin
            edge_reg_left <= left;
        end
    end

    assign falling_edge_left = edge_reg_left & (~left);
    assign rising_edge_left = (~edge_reg_left) & left;

//right
    logic edge_reg_right,falling_edge_right,rising_edge_right;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg_right <= 1'b0;
        end else begin
            edge_reg_right <= right;
        end
    end

    assign falling_edge_right = edge_reg_right & (~right);
    assign rising_edge_right = (~edge_reg_right) & right;

//put
    logic edge_reg_put,falling_edge_put,rising_edge_put;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg_put <= 1'b0;
        end else begin
            edge_reg_put <= put;
        end
    end

    assign falling_edge_put = edge_reg_put & (~put);
    assign rising_edge_put = (~edge_reg_put) & put;


//Display Panel Sync
    logic[9:0] rows,cols;
    logic en;

    always_ff@(posedge clk, posedge rst) begin 
        if(rst) en<=1;
        else en<=~en; 
    end

    always_ff@(posedge clk, posedge rst) begin 
        if(rst) cols <= 0;
        else begin
            if (en) begin
                cols <= (cols < 799) ? cols+1 : 0;
            end
        end
    end 

    always_ff@(posedge clk, posedge rst) begin 
        if(rst) rows <= 0;
        else begin
            if(en && (cols == 799)) begin
                rows <= (rows < 523) ? rows + 1 : 0; 
            end
        end
    end

    assign hsync = ~(cols>=655 && cols<751);
    assign vsync = ~(rows>=490 && rows<492);

//vars
logic[1:0] panel[5:0][6:0];
logic[2:0] count_panel[6:0], play;

//Next Move
always_ff@(posedge clk, posedge rst) begin 
    if(rst) begin 
        play <= 6; 
        for(int i = 0;i < 7;i++) begin 
            for(int j = 0;j < 6;j++) begin 
                panel[j][i] <= 0;
            end 
            count_panel[i] <= 0; 
        end  
        invalid_move <= 0;  
        player <= 0;
    end else if(rising_edge_left) begin 
        if(play == 6) invalid_move <= 1; 
        else begin 
            play = play + 1; 
            invalid_move <= 0;
        end 
    end else if(rising_edge_right) begin 
        if(play == 0) invalid_move <= 1; 
        else begin 
            play = play - 1; 
            invalid_move <= 0;
        end 
    end else if(rising_edge_put) begin 
        if(count_panel[play] == 6) begin 
            invalid_move <= 1;
        end else begin 
            player <= ~player;
            invalid_move <= 0;
            count_panel[play] <= count_panel[play] + 1;
            panel[count_panel[play]][play] <= (player) ? 2'b10:2'b01;
        end 
    end 
end 

//Winner
always_comb begin 
	win_a = 0; 
	win_b = 0;
//Vertical
    for(int i = 0;i < 7;i++) begin 
        for(int j = 0;j < 3;j++) begin 
            if(panel[j][i] == panel[j+1][i] && panel[j][i] == panel[j+2][i] && panel[j][i] == panel[j+3][i] && (panel[j][i] == 1 || panel[j][i] ==2)) begin 
                win_a = (panel[j][i] == 1) ? 1:0;
                win_b = (panel[j][i] == 2) ? 1:0;
			end
        end 
    end 
//Horizontal
    for(int i = 0;i < 4;i++) begin 
        for(int j = 0;j < 6;j++) begin 
            if(panel[j][i] == panel[j][i+1] && panel[j][i] == panel[j][i+2] && panel[j][i] == panel[j][i+3] && (panel[j][i] == 1 || panel[j][i] ==2)) begin 
                win_a = (panel[j][i] == 1) ? 1:0;
                win_b = (panel[j][i] == 2) ? 1:0;
			end
        end 
    end 
//Diagonal_L
    for(int i = 0;i < 4;i++) begin
        for(int j = 0;j < 3;j++) begin 
            if(panel[j][i] == panel[j+1][i+1] && panel[j][i] == panel[j+2][i+2] && panel[j][i] == panel[j+3][i+3] && (panel[j][i] == 1 || panel[j][i] ==2)) begin 
                win_a = (panel[j][i] == 1) ? 1:0;
                win_b = (panel[j][i] == 2) ? 1:0;
            end 
        end 
    end 
//Diagonal_R
    for(int i = 3;i < 7;i++) begin 
        for(int j = 0;j < 3;j++) begin 
            if(panel[j][i] == panel[j+1][i-1] && panel[j][i] == panel[j+2][i-2] && panel[j][i] == panel[j+3][i-3] && (panel[j][i] == 1 || panel[j][i] ==2)) begin
                win_a = (panel[j][i] == 1) ? 1:0;
                win_b = (panel[j][i] == 2) ? 1:0;
            end
        end 
    end 
end

//Full_panel
assign full_panel = (count_panel[0] + count_panel[1] + count_panel[2] + count_panel[3] + count_panel[4] + count_panel[5] + count_panel[6] == 42);

//RGB
always_comb begin 
/*
    for(int i = 0,count_c = 6;i < 7;i++,count_c--) begin 
        for(int j = 0,count_r = 5;j < 6;j++,count_r--) begin 
        //player_0_red_clr
            if(cols >= (((i+1)*30)+(i*50)) && cols < ((i+1)*80) && rows >= (((j+1)*8)+(j*51)) && rows < ((j+1)*59) && panel[count_r][count_c] == 2'b01) begin
                red = 4'b1111;
                green = 4'b0000;
                blue = 4'b0000; 
            end else if(cols >= (((i+1)*30)+(i*50)) && cols < ((i+1)*80) && rows >= 362 && rows < 413 && play == count_c && player == 0) begin
                red = 4'b1111;
                green = 4'b0000;
                blue = 4'b0000;
        //player_1_green_clr
            end else if(cols >= (((i+1)*30)+(i*50)) && cols < ((i+1)*80) && rows >= (((j+1)*8)+(j*51)) && rows < ((j+1)*59) && panel[count_r][count_c] == 2'b10) begin
                red = 4'b0000;
                green = 4'b1111;
                blue = 4'b0000; 
            end else if(cols >= (((i+1)*30)+(i*50)) && cols < ((i+1)*80) && rows >= 362 && rows < 413 && play == count_c && player) begin
                red = 4'b0000;
                green = 4'b1111;
                blue = 4'b0000;
        //info
            end else if(cols>=30 && cols<80 && rows>=421 && rows<472 && full_panel == 1) begin 
                red = 4'b0000;
                green = 4'b0000;
                blue = 4'b1111; 
            end else if(cols>=110 && cols<160 && rows>=421 && rows<472 && win_a == 1) begin 
                red = 4'b1111;
                green = 4'b0000;
                blue = 4'b0000; 
            end else if(cols>=110 && cols<160 && rows>=421 && rows<472 && win_b == 1) begin 
                red = 4'b0000;
                green = 4'b1111;
                blue = 4'b0000;
            end else if(cols>=190 && cols<240 && rows>=421 && rows<472 && invalid_move == 1) begin 
                red = 4'b1111;
                green = 4'b1111;
                blue = 4'b0000;
        //other
            end else begin
                red = 4'b0000;
                green = 4'b0000;
                blue = 4'b0000; 
            end 
        end
    end
*/
//old

//row1
    if(cols>=55 && cols<105 && rows>=8 && rows<59 && panel[5][6] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=8 && rows<59 && panel[5][5] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=8 && rows<59 && panel[5][4] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=8 && rows<59 && panel[5][3] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=8 && rows<59 && panel[5][2] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=8 && rows<59 && panel[5][1] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=8 && rows<59 && panel[5][0] == 2'b01) begin 
		red = 4'b1111; 
		green = 4'b0000;
		blue = 4'b0000;

//row_2
	end else if(cols>=55 && cols<105 && rows>=67 && rows<118 && panel[4][6] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=67 && rows<118 && panel[4][5] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=67 && rows<118 && panel[4][4] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=67 && rows<118 && panel[4][3] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=67 && rows<118 && panel[4][2] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=67 && rows<118 && panel[4][1] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=67 && rows<118 && panel[4][0] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;

//row_3
	end else if(cols>=55 && cols<105 && rows>=126 && rows<177 && panel[3][6] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=126 && rows<177 && panel[3][5] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=126 && rows<177 && panel[3][4] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=126 && rows<177 && panel[3][3] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=126 && rows<177 && panel[3][2] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=126 && rows<177 && panel[3][1] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=126 && rows<177 && panel[3][0] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;

//row_4
	end else if(cols>=55 && cols<105 && rows>=185 && rows<236 && panel[2][6] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=185 && rows<236 && panel[2][5] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=185 && rows<236 && panel[2][4] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=185 && rows<236 && panel[2][3] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=185 && rows<236 && panel[2][2] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=455 && cols<505 && rows>=185 && rows<236 && panel[2][1] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=185 && rows<236 && panel[2][0] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
//row_5
	end else if(cols>=55 && cols<105 && rows>=244 && rows<295 && panel[1][6] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=244 && rows<295 && panel[1][5] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=244 && rows<295 && panel[1][4] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=244 && rows<295 && panel[1][3] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=244 && rows<295 && panel[1][2] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=244 && rows<295 && panel[1][1] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=244 && rows<295 && panel[1][0] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;	
//row_6
	end else if(cols>=55 && cols<105 && rows>=303 && rows<354 && panel[0][6] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=135 && cols<185 && rows>=303 && rows<354 && panel[0][5] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=303 && rows<354 && panel[0][4] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=303 && rows<354 && panel[0][3] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=303 && rows<354 && panel[0][2] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=303 && rows<354 && panel[0][1] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=303 && rows<354 && panel[0][0] == 2'b01) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
//play
	end else if(cols>=55 && cols<105 && rows>=362 && rows<413 && play == 6 && player == 0) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=362 && rows<413 && play == 5 && player == 0) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=362 && rows<413 && play == 4 && player == 0) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=362 && rows<413 && play == 3 && player == 0) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=362 && rows<413 && play == 2 && player == 0) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=362 && rows<413 && play == 1 && player == 0) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=362 && rows<413 && play == 0 && player == 0) begin 
		red = 4'b1111;
		green = 4'b0000;
		blue = 4'b0000;

//player_1
//row1
    end else if(cols>=55 && cols<105 && rows>=8 && rows<59 && panel[5][6] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=135 && cols<185 && rows>=8 && rows<59 && panel[5][5] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=215 && cols<265 && rows>=8 && rows<59 && panel[5][4] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=8 && rows<59 && panel[5][3] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=8 && rows<59 && panel[5][2] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=8 && rows<59 && panel[5][1] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=8 && rows<59 && panel[5][0] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;

//row_2
	end else if(cols>=55 && cols<105 && rows>=67 && rows<118 && panel[4][6] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=135 && cols<185 && rows>=67 && rows<118 && panel[4][5] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=215 && cols<265 && rows>=67 && rows<118 && panel[4][4] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=67 && rows<118 && panel[4][3] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=67 && rows<118 && panel[4][2] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=67 && rows<118 && panel[4][1] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=67 && rows<118 && panel[4][0] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;

//row_3
	end else if(cols>=55 && cols<105 && rows>=126 && rows<177 && panel[3][6] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=135 && cols<185 && rows>=126 && rows<177 && panel[3][5] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=215 && cols<265 && rows>=126 && rows<177 && panel[3][4] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=126 && rows<177 && panel[3][3] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=126 && rows<177 && panel[3][2] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=126 && rows<177 && panel[3][1] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=126 && rows<177 && panel[3][0] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;

//row_4
	end else if(cols>=55 && cols<105 && rows>=185 && rows<236 && panel[2][6] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=185 && rows<236 && panel[2][5] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=185 && rows<236 && panel[2][4] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=185 && rows<236 && panel[2][3] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=185 && rows<236 && panel[2][2] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=185 && rows<236 && panel[2][1] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=185 && rows<236 && panel[2][0] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
//row_5
	end else if(cols>=55 && cols<105 && rows>=244 && rows<295 && panel[1][6] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=135 && cols<185 && rows>=244 && rows<295 && panel[1][5] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=244 && rows<295 && panel[1][4] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=244 && rows<295 && panel[1][3] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=244 && rows<295 && panel[1][2] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=244 && rows<295 && panel[1][1] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=244 && rows<295 && panel[1][0] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;	
//row_6
	end else if(cols>=55 && cols<105 && rows>=303 && rows<354 && panel[0][6] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=135 && cols<185 && rows>=303 && rows<354 && panel[0][5] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000; 
	end else if(cols>=215 && cols<265 && rows>=303 && rows<354 && panel[0][4] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=303 && rows<354 && panel[0][3] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=303 && rows<354 && panel[0][2] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=303 && rows<354 && panel[0][1] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=303 && rows<354 && panel[0][0] == 2'b10) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
//play
	end else if(cols>=55 && cols<105 && rows>=362 && rows<413 && play == 6 && player == 1) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000; 
	end else if(cols>=135 && cols<185 && rows>=362 && rows<413 && play == 5 && player == 1) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=215 && cols<265 && rows>=362 && rows<413 && play == 4 && player == 1) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=295 && cols<345 && rows>=362 && rows<413 && play == 3 && player == 1) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=475 && cols<425 && rows>=362 && rows<413 && play == 2 && player == 1) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=455 && cols<505 && rows>=362 && rows<413 && play == 1 && player == 1) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;
	end else if(cols>=535 && cols<585 && rows>=362 && rows<413 && play == 0 && player == 1) begin 
		red = 4'b0000;
		green = 4'b1111;
		blue = 4'b0000;

//game_info
    end else if(cols>=30 && cols<80 && rows>=421 && rows<472 && full_panel == 1) begin 
        red = 4'b0000;
        green = 4'b0000;
        blue = 4'b1111; 
    end else if(cols>=110 && cols<160 && rows>=421 && rows<472 && win_a == 1) begin 
        red = 4'b1111;
        green = 4'b0000;
        blue = 4'b0000; 
    end else if(cols>=110 && cols<160 && rows>=421 && rows<472 && win_b == 1) begin 
        red = 4'b0000;
        green = 4'b1111;
        blue = 4'b0000;
    end else if(cols>=190 && cols<240 && rows>=421 && rows<472 && invalid_move == 1) begin 
        red = 4'b1111;
        green = 4'b1111;
        blue = 4'b0000;
//else 
	end else begin 
		red = 4'b0000;
		green = 4'b0000;
		blue = 4'b0000;
	end 

    
end 


endmodule