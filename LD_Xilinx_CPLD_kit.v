

module LD_Xilinx_CPLD_kit (
    input [7:0] i_inh, //0:laser key 1:doorkey 2:door sens 3: PO-1 LDdisabele 4: LDACP 5:Po-2 frmrate 6:Po3 7:PonDelay
    output [3:0] o_out,//0: Laser ind 1:Laser shutter 2:RC 3:AVR:ENA
    output [3:0] o_onbd_led,//0:pw5ms 1:ExtPls 2:Cam20Hz 3:Remmode
    output o_cam_trg,
    output reg o_led2, 
    input i_clk,// 50MHz
    input i_rst,//lowactive
    input i_sig, //外部パルス入力
    input [3:0] i_pw_set,//pw設定用SW 4bit
    input [1:0] i_dip, // 0:PW分解能変更 1:内部/外部パルス切り替え
    output c_clk,
    output c_frq,
    output c_ldtrg,
    output c_vco,
    output c_pul_stat,
    output c_cam_trg,
    output c_led2
);

//reg 
reg [20:0] pw_cnt;
reg [20:0] cnt;
reg [19:0] cnt_frq;// 周波数生成用cnt
reg pulse_state;
reg [1:0] pulse_end;
reg frq_out;
reg vco_up;
reg ld_trg;
reg cam_trg;
reg cw_pls; //パルス幅設定が0でpulseは連続出力
reg stop_pls; //パルス幅設定以上でpulse出力停止


//wire 
wire vco_up_ex;
wire vco_up_in;


//パラメーター
parameter CNT_5MS = 50000; //設定時間 X クロック周波数 5msec = 5/1000 * 10MHHz
parameter DELAY_LD = 1000; //設定時間 X クロック周波数 0.1msec = 0.1/1000 * 10MHz
parameter FRQ_SYNC = 250000 - 1; //(クロック周波数/作りたい周波数) / 2 -1　(10MHz/20Hz)/2-1

PLL (
	.inclk0(i_clk),
	.c0(sys_clk),
	.c1(lo_clk) // = 50Mhz /5 = 10MHz
	);

edge_detect u0(
     // Input
     .i_clk(lo_clk),
     .i_rst(i_rst),
     .i_sig(i_sig),
     // Output
     .o_up1(vco_up_ex),
     .o_up2(),
     .o_dn1(),
     .o_dn2()
);

edge_detect u1(
     // Input
     .i_clk(lo_clk),
     .i_rst(i_rst),
     .i_sig(frq_out),
     // Output
     .o_up1(vco_up_in),
     .o_up2(),
     .o_dn1(),
     .o_dn2()
);


//内部で周波数を生成する
 always @(posedge lo_clk) 
 begin if(~i_rst) begin
          cnt_frq <= 0;
          frq_out <= 0;
     end else if(cnt_frq >= (FRQ_SYNC  * (i_inh[5] + 1)) + i_inh[5])begin //Dip SWの設定により10Hz/20Hz切り替え dip Hで10hz
          frq_out <= ~frq_out;
          cnt_frq <= 0;
     end else begin
          cnt_frq <= cnt_frq + 1;
	end
 end 

//内部SWを用いて周波数周波数
always @(posedge lo_clk)
    begin if(i_dip[1]) begin
        vco_up <= vco_up_in;
    end else begin
        vco_up <= vco_up_ex;
    end
    end


//Pw設定用SWの入力値計算
always @(posedge lo_clk)
begin
    if(~pulse_state)begin //パルス出力中は設定を変更しない
        case (i_dip[0]) 
            1'b0: // 5ms 分解能
                pw_cnt <= 50000 * i_pw_set; // 5ms単位
            1'b1: // 10ms 分解能
                pw_cnt <= 100000 * i_pw_set; // 10ms単位
        endcase
        
        if(pw_cnt == 0)begin // pwcntの設定が0の時はCW出力
            cw_pls <= 1;
        end else begin
            cw_pls <= 0;
        end

        if(i_inh[5] == 1 && i_dip[0] == 1 && i_pw_set >= 10) begin //fr 10 Hz Pw 10msec 設定 A以上で停止
            stop_pls <= 1;
        end else if(i_inh[5] == 0 && i_dip[0] == 1 && i_pw_set >= 5) begin //fr 20 Hz Pw 10msec 設定 5以上で停止
            stop_pls <= 1;
        end else if(i_inh[5] == 0 && i_dip[0] == 0 && i_pw_set >= 10) begin //fr 20 Hz Pw 5msec 設定 A以で停止
            stop_pls <= 1;    
        end else begin
            stop_pls <= 0;
        end
    end
end

//edge_detect 検出後カウンタ値を用いて　所定の時間出力するmodule
always @(posedge lo_clk)
     begin if (~i_rst || stop_pls)begin
            cnt <= 0;
            pulse_state <= 0; 
            pulse_end <= 2'b00;
            cam_trg <= 0;
            o_led2 <= 0;//led2 off
            ld_trg <= 0;//delay triga off

        end else if (vco_up &&!pulse_state) begin
            // パルス開始を検出
            cnt <= 0;       // パルス幅をリセット
            pulse_state <= 1;      // パルス状態を記録
            pulse_end <= 2'b00;
            cam_trg <= 1;//カメラトリガon
            o_led2 <= 1;//led2 on

        end else if (pulse_state) begin
            //Cam Trig 制御部
            if (cnt >= CNT_5MS) begin
                    cam_trg <= 0;
                    pulse_end[0] <= 1;
                end 

            //LED2 制御部
            if (cnt >= pw_cnt) begin
                    o_led2 <= 0;
                    pulse_end[1] <= 1;
                end 
            
            //Ld Trg 制御部
            if (cnt >= (pw_cnt - DELAY_LD)) begin
                    ld_trg <= 0;
            
            //ld trg 出力は遅延させる
                end else if (cnt >= DELAY_LD)  begin
                    ld_trg <= 1;
                end else begin
                    ld_trg <= 0;
                end 

            //マスターカウント制御
            if (pulse_end == 2'b11)  begin
                cnt <= 0;
                pulse_state <= 0;

            end else begin
                cnt <= cnt +1;
            end
            //CW 設定値の際は出力し続ける設定
            if(cw_pls == 1)begin
                ld_trg <= 1;
                o_led2 <= 1;
                pulse_end[1] <= 1;//カメラトリガはsyncに同期させる
            end
     end 
    end


//論理積
//in 0:laser key 1:doorkey 2:door sens 3: PO-1 LDdisabele 4: LD ACP OH 5:Po-2 frmrate 6:Po3 7:PonDelay
//out 0: Laser ind 1:Laser shutter 2:RC 3:AVR:ENA
assign o_cam_trg = ~cam_trg;
assign o_out[0] = ~i_inh[0];
assign o_out[1] = ~(~i_inh[0] && ~i_inh[1] && ~i_inh[2] && i_inh[3] && ~i_inh[4]);
wire intlks;
assign intlks = i_inh[0] || i_inh[4];
assign o_out[2] = ~(ld_trg && ~intlks); 
assign o_out[3] = ~i_inh[4] && i_inh[7];

// LED 0:pw5ms 1:ExtPls 2:Cam20Hz 3:Remmode
assign o_onbd_led[0] = i_dip[0];//5mscモード dip sw"L"で点灯
assign o_onbd_led[1] = i_dip[1];//外部モード dip sw"L"で点灯
assign o_onbd_led[2] = i_inh[5];//Frmrate 20fpsで点灯
//assign o_onbd_led[3] = ~i_inh[6];//Remmodeで"H"で点灯
assign c_clk = lo_clk;
assign c_frq = frq_out;
assign c_ldtrg = ld_trg;
assign c_vco = vco_up;
assign c_cam_trg = cam_trg;
assign c_led2 = o_led2;


endmodule