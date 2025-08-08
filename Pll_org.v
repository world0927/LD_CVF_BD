module PLL_ORG #(parameter DIVIDER = 8) (
	input inclk,
	output reg c0,
	output reg c1);
    
    reg [9:0] cnt; // 2048まで　

always @(posedge inclk0k) begin
    c0 <= inclk0;
    if(cnt == (DIVIDER / 2 -1)) begin
        c1 <= ~c1;
        cnt <= 0;
    end
    else begin
        cnt <= cnt + 1;
    end
end

endmodule