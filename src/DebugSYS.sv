`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
// 
// Create Date: 19.10.2019 23:14:17
// Design Name: 
// Module Name: DebugSYS
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// START: Коды состояний TAP-контроллера
localparam [3:0] STATE_TEST_LOGIC_RESET   = 4'b0000;
localparam [3:0] STATE_RUN_TEST_IDLE      = 4'b0001;
localparam [3:0] STATE_SELECT_DR_SCAN     = 4'b0010;
localparam [3:0] STATE_CAPTURE_DR         = 4'b0011;
localparam [3:0] STATE_SHIFT_DR           = 4'b0100;
localparam [3:0] STATE_EXIT1_DR           = 4'b0101;
localparam [3:0] STATE_PAUSE_DR           = 4'b0110;
localparam [3:0] STATE_EXIT2_DR           = 4'b0111;
localparam [3:0] STATE_UPDATE_DR          = 4'b1000;
localparam [3:0] STATE_SELECT_IR_SCAN     = 4'b1001;
localparam [3:0] STATE_CAPTURE_IR         = 4'b1010;
localparam [3:0] STATE_SHIFT_IR           = 4'b1011;
localparam [3:0] STATE_EXIT1_IR           = 4'b1100;
localparam [3:0] STATE_PAUSE_IR           = 4'b1101;
localparam [3:0] STATE_EXIT2_IR           = 4'b1110;
localparam [3:0] STATE_UPDATE_IR          = 4'b1111;
// END: Коды состояний TAP-контроллера

// START: Коды инструкций
localparam [3:0] CMD_BYPASS               = 4'b1111;
localparam [3:0] CMD_SAMPLE_PRELOAD       = 4'b0001;
localparam [3:0] CMD_EXTEST               = 4'b0010;
localparam [3:0] CMD_INTEST               = 4'b0011;
localparam [3:0] CMD_IDCODE               = 4'b0100;
// END: Коды инструкций

// START: Кодирование номеров Data-регистров
localparam [2:0] NUM_BYPASS               = 3'b000;
localparam [2:0] NUM_DEVICEID             = 3'b001;
localparam [2:0] NUM_BSR                  = 3'b010;
// END: Кодирование номеров Data-регистров

// START: Размеры регистров Core_Logic и, соответственно, BSR
localparam [2:0] INPUT_WIDTH              = 5;
localparam [2:0] OUTPUT_WIDTH             = 4;
localparam [3:0] TOTAL_WIDTH              = INPUT_WIDTH + OUTPUT_WIDTH;
// END: Размеры регистров Core_Logic


module DebugSYS(
    input                           TCK,
    input                           TMS,
    input                           TDI,
    output reg                      TDO,

    input  [INPUT_WIDTH-1:0]         from_SYS_to_BSR,
    output [INPUT_WIDTH-1:0]         from_BSR_to_CL,
    input  [OUTPUT_WIDTH-1:0]        from_CL_to_BSR,
    output [OUTPUT_WIDTH-1:0]        from_BSR_to_SYS
    );

    // START: Определения сигналов

    // START: TAP Controller
    reg         enable;         // Сигнал выходной логики [0] - TDO в Z-состоянии, [1] - TDO выводит данные Data-регистра или Instruction-регистра
    reg         select;         // Сигнал выходной логики [0] - выводить данные DR(Data регистр), [1] - выводить данные IR(Instruction регистр)
    reg         clk_DR;         // Разрешение тактирования DR
    reg         update_DR;      // Загрузить данные из сдвигового регистра DR в основной
    reg         shift_DR;       // Разрешение сдвига DR
    reg         clk_IR;         // Разрешение тактирования IR
    reg         update_IR;      // Загрузить данные из сдвигового регистра IR в основной
    reg         shift_IR;       // Разрешение сдвига IR

    reg [3:0]   state           = STATE_TEST_LOGIC_RESET; // Текущее состояние конечного автомата(FSM) TAP-контроллера. Начинаем с ресета
    // END: TAP Controller

    // START: Регистр инструкций(IR)
    reg         clock_IR;       // Тактовый сигнал для IR
    reg         tdo_IR;         // Данные из сдвигового регистра на выход TDO
    reg [2:0]   num_DR;         // Управляющий сигнал. Номер регистра DR, который должен быть замкнут между TDI и TDO. Зависит от содержимого основного регистра IR.
    reg         intest;         // Управляющий сигнал intest для BSR
    reg         extest;         // Управляюший сигнал extest для BSR

    reg [3:0]   shifted_IR      = CMD_IDCODE; // Сдвиговый регистр. По-умолчанию стартуем с IDCODE
    reg [3:0]   main_IR         = CMD_IDCODE; // Основной регистр. По-умолчанию стартуем с IDCODE
    // END: Регистр инструкций(IR)

    // START: Логика тактирования и вывода для Data регистров
    reg         clock_bypass;   // Тактовый сигнал для регистра BYPASS
    reg         clock_deviceID; // Тактовый сигнал для регистра DeviceID
    reg         clock_BSR;      // Тактовый сигнал для регистра BSR
    reg         tdo_DR;         // Данные из DR, который должен быть замкнут между TDI и TDO
    // END: Логика тактирования и вывода для Data регистров

    // START: Device ID register
    reg         tdo_deviceID;       // Данные на выход TDO из сдвигового Device_ID
    reg [31:0]  shifted_deviceID;   // Сдвиговый регистр. Основной регистр тут не нужен, так как DeviceID не должен принимать данные из TDI и защелкиваться по UPDATE_DR
    // END: Device ID register

    // START: Bypass register
    reg         tdo_bypass;     // Данные на выход TDO
    reg         bypass;         // Сдвиговый регистр bypass. Основной не нужен, причина такая же как и у DeviceID
    // END: Bypass register

    // START: BSR register
    reg         tdo_BSR;                    // Данные на выход TDO из сдвигового регистра BSR
    reg [TOTAL_WIDTH-1:0]   shifted_BSR;    // Сдвиговый регистр BSR. Для конкретного случая с текущей COre Logic - [8:4] - input, [3:0] - output
    reg [TOTAL_WIDTH-1:0]   main_BSR;       // Основной регистр BSR.
    // END: BSR register

    // START: Сигналы для логики вывода
    reg tdo_output;     // Содержит данные из регистров tdo_*, которые идут напрямую в TDO
    // END: Сигналы для логики вывода

    // END: Определения сигналов


    // START: TAP Controller FSM
    always@(posedge TCK) // Логика переключения состояний. Состояния переключаются ТОЛЬКО по фронту TCK
    begin
        case(state)

        STATE_TEST_LOGIC_RESET: begin
            if (!TMS) begin
                state = STATE_RUN_TEST_IDLE;
            end
        end

        STATE_RUN_TEST_IDLE: begin
            if(TMS)
                state = STATE_SELECT_DR_SCAN;
        end

        STATE_SELECT_DR_SCAN: begin
            if (TMS)
                state = STATE_SELECT_IR_SCAN;
            else
                state = STATE_CAPTURE_DR;
        end

        STATE_CAPTURE_DR: begin
            if (TMS)
                state = STATE_EXIT1_DR;
            else
                state = STATE_SHIFT_DR;
        end

        STATE_SHIFT_DR: begin
            if (TMS)
                state = STATE_EXIT1_DR;
        end

        STATE_EXIT1_DR: begin
            if (TMS)
                state = STATE_UPDATE_DR;
            else
                state = STATE_PAUSE_DR;
        end

        STATE_PAUSE_DR: begin
            if (TMS)
                state = STATE_EXIT2_DR;
        end

        STATE_EXIT2_DR: begin
            if(TMS)
                state = STATE_UPDATE_DR;
            else
                state = STATE_SHIFT_DR;
        end

        STATE_UPDATE_DR: begin
            if (TMS)
                state = STATE_SELECT_DR_SCAN;
            else
                state = STATE_RUN_TEST_IDLE;
        end

        STATE_SELECT_IR_SCAN: begin
            if(TMS)
                state = STATE_TEST_LOGIC_RESET;
            else
                state = STATE_CAPTURE_IR;
        end

        STATE_CAPTURE_IR: begin
            if(TMS)
                state = STATE_EXIT1_IR;
            else
                state = STATE_SHIFT_IR;
        end

        STATE_SHIFT_IR: begin
            if (TMS)
                state = STATE_EXIT1_IR;
        end

        STATE_EXIT1_IR: begin
            if (TMS)
                state = STATE_UPDATE_IR;
            else
                state = STATE_PAUSE_IR;
        end

        STATE_PAUSE_IR: begin
            if (TMS)
                state = STATE_EXIT2_IR;
        end

        STATE_EXIT2_IR: begin
            if (TMS)
                state = STATE_UPDATE_IR;
            else
                state = STATE_SHIFT_IR;
        end

        STATE_UPDATE_IR: begin
            if (TMS)
                state = STATE_SELECT_DR_SCAN;
            else
                state = STATE_RUN_TEST_IDLE;
        end

        endcase
    end

    always@(negedge TCK) // Подача управляющих сигналов. Они подаются ТОЛЬКО по спаду TCK. То есть, по фрону - переключили состояние, по следуюшему спаду - подали контрольные сигналы, соответствующие состоянию
    begin
        case(state)

        STATE_TEST_LOGIC_RESET: begin
            update_DR   = 0;
            shift_DR    = 0;
            update_IR   = 0;
            shift_IR    = 0;
            clk_DR      = 0;
            clk_IR      = 0;
            enable      = 0; // отключаем вывод, переводим TDO в Z-состояние
            select      = 0;
        end

        STATE_RUN_TEST_IDLE: begin // Одно из двух возможных состояний после UPDATE_DR или UPDATE_IR. Необходимо занулить оба сигнала
            update_IR = 0;
            update_DR = 0;
        end

        STATE_SELECT_DR_SCAN: begin // Второе из двух возможные состояний после UPDATE
            update_IR = 0;
            update_DR = 0;
        end

        STATE_CAPTURE_DR: begin
            select = 0; // выбираем DR в логике вывода
            clk_DR = 1; // начинаем тактирование выбранного DR
        end

        STATE_SHIFT_DR: begin // каждый сдвиг должен осуществляться по фронту TCK. Как только мы вошли в SHIFT_DR(по фронту TCK), никакого сдвига не произошло, так как управляющий сигнал Shift_DR занулён. В этом месте, по спаду TCK мы устанавливаем SHIFT_DR в 1, разрешая сдвиги, таким образом сдвиг произойдет ПО СЛЕДУЮЩЕМУ ФРОНТУ
            shift_DR = 1;
            enable = 1;     // несмотря на это, мы разрешаем вывод, таким образом, на TDO подается самое крайнее значение [0] регистра DR
        end

        STATE_EXIT1_DR: begin // Как только мы вошли в это состояние(по фронту TCK), shift_DR не занулён и будет совершён еще один сдвиг.
            shift_DR = 0;
            enable = 0;
            clk_DR = 0;
        end

        STATE_PAUSE_DR: begin
        end

        STATE_EXIT2_DR: begin
        end

        STATE_UPDATE_DR: begin
            update_DR = 1; // обновляем основной регистр DR содержимым сдвигового
        end

        // Все комментарии описаные к DR-состоянием применимы и к IR-состояням

        STATE_SELECT_IR_SCAN: begin 
        end

        STATE_CAPTURE_IR: begin
            select = 1;
            shift_IR = 0;
            clk_IR = 1;
        end

        STATE_SHIFT_IR: begin
            shift_IR = 1;
            enable = 1;
        end

        STATE_EXIT1_IR: begin
            shift_IR = 0;
            enable = 0;
            clk_IR = 0;
        end

        STATE_PAUSE_IR: begin
        end

        STATE_EXIT2_IR: begin
        end

        STATE_UPDATE_IR: begin
            update_IR = 1;
        end

        endcase
    end
    // END: TAP Controller FSM

    // START: Регистр инструкций и декодирование инструкций
    assign clock_IR = (clk_IR == 1'b1) ? TCK : 1'b0;
    assign tdo_IR = shifted_IR[0];

    // Логика контрольных сигналов
    assign num_DR = (main_IR == CMD_BYPASS) ? NUM_BYPASS :
                    (main_IR == CMD_IDCODE) ? NUM_DEVICEID :
                    (main_IR == CMD_SAMPLE_PRELOAD || main_IR == CMD_INTEST || main_IR == CMD_EXTEST) ? NUM_BSR :
                    3'b111;
    assign extest   = (main_IR == CMD_EXTEST) ? 1'b1 : 1'b0;
    assign intest   = (main_IR == CMD_INTEST) ? 1'b1 : 1'b0;

    always@(posedge clock_IR)
    begin
        if (shift_IR) begin
            shifted_IR <= {TDI, shifted_IR[3:1]};
        end
    end

    always@(posedge update_IR)
    begin
        main_IR = shifted_IR;
    end
    // END: Регистр инструкций

    // START: Тактовые сигналы для всех DR. Кроме того, здесь описана логика замыкания между TDI и TDO. По-умолчанию TDI идет в каждый регистр, но выводить данные в TDO должен только один
    assign clock_bypass     = (clk_DR == 1'b1 && num_DR == NUM_BYPASS) ? TCK : 1'b0;
    assign clock_deviceID   = (clk_DR == 1'b1 && num_DR == NUM_DEVICEID) ? TCK : 1'b0;
    assign clock_BSR        = (clk_DR == 1'b1 && num_DR == NUM_BSR) ? TCK : 1'b0;

    assign tdo_DR = (num_DR == NUM_BYPASS) ? tdo_bypass :
                    (num_DR == NUM_DEVICEID) ? tdo_deviceID :
                    (num_DR == NUM_BSR) ? tdo_BSR :
                    1'bZ;
    // END: Тактовые сигналы для всех DR

    // START: Логика вывода
    assign TDO = enable ? tdo_output : 1'bZ;
    always@(negedge TCK)
    begin
        tdo_output = select ? tdo_IR : tdo_DR;
    end
    // END: Логика вывода

    // START: deviceID register
    assign tdo_deviceID = shifted_deviceID[0];

    always@(posedge clock_deviceID)
    begin
        if (shift_DR) begin
            shifted_deviceID = {1'b1, shifted_deviceID[31:1]};
        end else begin
            shifted_deviceID = 32'hDEAD104D;
        end
    end
    // END: deviceID register

    // START: Bypass register
    assign tdo_bypass = bypass;

    always@(posedge clock_bypass)
    begin
        if (shift_DR)
            bypass <= TDI;
        else
            bypass <= 0;
    end
    // END: Bypass register

    // START: BSR
    assign tdo_BSR = shifted_BSR[0];

    assign from_BSR_to_CL = (intest == 1'b1) ? main_BSR[TOTAL_WIDTH-1:OUTPUT_WIDTH] : from_SYS_to_BSR;
    assign from_BSR_to_SYS = (extest == 1'b1) ? main_BSR[OUTPUT_WIDTH-1:0] : from_CL_to_BSR;

    always@(posedge clock_BSR)
    begin
        if (shift_DR) begin
            shifted_BSR <= {TDI, shifted_BSR[TOTAL_WIDTH-1:1]};
        end 
        else begin
            shifted_BSR = {from_SYS_to_BSR, from_CL_to_BSR}; 
        end
    end

    always@(posedge update_DR)
    begin
        main_BSR = shifted_BSR;
    end
    // END: BSR

endmodule