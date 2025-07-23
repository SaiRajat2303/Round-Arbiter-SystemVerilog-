// Code your design here
module round_robin_arbiter #(
    parameter int NUM_REQUESTS = 4,
    parameter NUM_CLK_GRANT = 4
)(
    input clk,
    input reset,
    input logic [NUM_REQUESTS-1:0] req,
    output logic [NUM_REQUESTS-1:0] grant
);

typedef enum {IDLE, GNT_0, GNT_1, GNT_2, GNT_3} state_t;
state_t current_state, next_state;
localparam CNT_WIDTH = $clog2(NUM_CLK_GRANT);
logic [CNT_WIDTH-1:0] count;
logic [CNT_WIDTH-1:0] next_count;

  always_ff@(posedge clk or posedge reset) begin 
    if (reset) begin
        current_state <= IDLE;
        count <= 0;
    end 
    else begin
        current_state <= next_state;
        count <= next_count;
    end
end

always_comb begin
    next_state = current_state;
    next_count = count;
    grant = NUM_REQUESTS'(0); // Default no grant
    // initializations
    case(current_state)
        IDLE: begin
            if(!reset) begin 
                // If you are out of reset , transition to next state
              if(req[0] == 1'b1) begin
                    next_state = GNT_0;
                    grant[0] = 1'b1;
                    next_count = count + 1; // because we have given a grant already 
                    // We cant do count = 1 (because count is already being driven sequentially)
                    // next count logic should just increment this count
                end
                else if (req[1] == 1'b1) begin
                    next_state = GNT_1;
                    grant[1] = 1'b1;
                    next_count = count + 1;
                end
                else if (req[2] == 1'b1) begin
                    next_state = GNT_2;
                    grant[2] = 1'b1;
                    next_count = count + 1;
                end
                else if (req[3] == 1'b1) begin
                    next_state = GNT_3;
                    grant[3] = 1'b1;
                    next_count = count + 1;
                end
                else begin
                    next_state = IDLE;
                    next_count = 0; // Reset count
                end
            end
            else begin
                next_state = IDLE; // still in reset
            end
        end

        GNT_0 : begin
            if(req[0]) begin
                if(count < NUM_CLK_GRANT - 1) begin
                    next_count = count + 1;
                    grant[0] = 1'b1;
                    next_state = GNT_0;
                end
                else if(count == NUM_CLK_GRANT - 1) begin
                    next_count = 0;
                    grant[0] = 1'b1; // Keep it high for current cycle
                    next_state = req[1] ? GNT_1 : (req[2] ? GNT_2 : (req[3] ? GNT_3 : GNT_0)); // nested condition to decide the next grant
                    // Assumption here is : If a requester is requesting access , its request line wont go down next cycle (can cause protocol violations)
                end
            end
            else begin
                next_count = 0;
                grant[0] = 1'b0;
                next_state = req[1] ? GNT_1 : (req[2] ? GNT_2 : (req[3] ? GNT_3 : GNT_0)); 
            end
        end
        
        
        GNT_1: begin
            if(req[1]) begin
                if(count < NUM_CLK_GRANT - 1) begin
                    next_count = count + 1;
                    grant[1] = 1'b1;
                    next_state = GNT_1;
                end
                else if (count == NUM_CLK_GRANT - 1) begin
                    next_count = 0;
                    grant[1] = 1'b1;
                    next_state = req[2] ? GNT_2 : (req[3] ? GNT_3 : (req[0] ? GNT_0 : GNT_1));
                end
            end
            else begin
                next_count = 0;
                grant[1] = 1'b0;
                next_state = req[2] ? GNT_2 : (req[3] ? GNT_3 : (req[0] ? GNT_0 : GNT_1));
            end
        end

        GNT_2: begin
            if(req[2]) begin
                if(count < NUM_CLK_GRANT - 1) begin
                    next_count = count + 1;
                    grant[2] = 1'b1;
                    next_state = GNT_2;
                end
                else if (count == NUM_CLK_GRANT - 1) begin
                    next_count = 0;
                    grant[2] = 1'b1;
                    next_state = req[3]? GNT_3 : (req[0] ? GNT_0: (req[1] ? GNT_1 : GNT_2));
                end
            end
            else begin
                next_count = 0;
                grant[2] = 1'b0;
                next_state = req[3]? GNT_3 : (req[0] ? GNT_0: (req[1] ? GNT_1 : GNT_2));
            end
        end

        GNT_3: begin
            if(req[3]) begin
                if(count < NUM_CLK_GRANT - 1) begin
                    next_count = count + 1;
                    grant[3] = 1'b1;
                    next_state = GNT_3;
                end
                else if (count == NUM_CLK_GRANT - 1) begin
                    next_count = 0;
                    grant[3] = 1'b1;
                    next_state = req[0]? GNT_0 : (req[1] ? GNT_1: (req[2] ? GNT_2 : GNT_3));
                end
            end
            else begin
                next_count = 0;
                grant[3] = 1'b0;
                next_state = req[0]? GNT_0 : (req[1] ? GNT_1: (req[2] ? GNT_2 : GNT_3));
            end
        end

        default: begin
            next_count = 0;
            grant = NUM_REQUESTS'(1'b0);
            next_state = IDLE;
        end

    endcase
end

endmodule
