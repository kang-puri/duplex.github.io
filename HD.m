clc; clear; close all;

%-------------------------set up----------------------------

data_rate = 18;
PHY_header = 20; 
PHY_preamble = 16;  %microseconds
RTS_size = 20*8;
CTS_size = 14*8;
ACK_size = 14*8;
Payload = 1500*8;   %bytes
SIFS = 16; 
DIFS = 34; 
slot_time = 9;

MAC_header = 10;

ACK = ACK_size/data_rate + PHY_header + PHY_preamble;  
RTS = RTS_size/data_rate + PHY_header + PHY_preamble;
CTS = CTS_size/data_rate + PHY_header + PHY_preamble;  

H = MAC_header + PHY_header;

Ts = RTS + 3 * SIFS + CTS + H + Payload/data_rate + ACK + DIFS;
Tc = RTS + DIFS;
Tsa = RTS + 3 * SIFS + CTS + H + Payload/data_rate + ACK + DIFS + slot_time;
Tca = RTS + DIFS + slot_time;

m_max = 6;
CW_min = 15;

throughput_Si = [];
p_si = [];
succ = [];
for N=5:5:40

    % N=5,10,15,20,25,30,35,40 (number of node)
    
    succ_num = 0;
    idle_num = 0;
    coll_num = 0;
    
    CW = CW_min;
   
    count = randi([0 CW], 1, N);
    stage = zeros(1,N);
    state = [count ; stage];
    sys_time = 0;
    T = 10^3;

    %---------------------------전송시작-------------------------
    
    for k = 1:10^5
        %pause(1)
        %N
        %state
        %succ_num
        %colli_num
        %node_trans

        %fprintf('-----------------------------------------------------------');
        

        % 0 개수
        col = find(state(1,:) == 0);
        n = numel(col);

        freeze = 1;

        % 1) idle
        if n == 0
            sys_time = sys_time + slot_time;
            idle_num = idle_num + 1;                 

        % 2) 0이 한 개 (NO Collision) 
        elseif n == 1
            succ_num = succ_num + 1;
            freeze = 0; 
            sys_time = sys_time + Ts;

            for i = 1:N
                if state(1,i) == 0
                    state(2,i) = 0;
                    state(1,i) = randi([0 CW]);
                end
            end

        % 3) 0이 둘 이상 (Collision)         
        elseif n > 1
            freeze = 0;
            sys_time = sys_time + Tc;
            coll_num = coll_num + 1;
            for i = 1:N
                if state(1,i) == 0
                    if state(2,i) < m_max
                        state(2,i) = state(2,i) + 1;
                        state(1,i) = randi([0 CW*(2^state(2,i))-1]);

                    elseif state(2,i) == m_max
                        state(1,i) = randi([0 CW*(2^m_max)-1]);
                    end
                end
            end
        end

        if freeze > 0
            state(1,:) = state(1,:) - ones(1);
        end

    end

    S_sim = succ_num*(Payload)/sys_time;
    throughput_Si = [throughput_Si, S_sim]; 

    prob_s = succ_num/(succ_num + coll_num);
    %succ_num/idle
    p_si = [p_si, prob_s];
    Ps_Si = mean(p_si);
   % 총 성공적인 전송/총 전송횟수
   %succ = [succ, succ_num];
   %succ
end





%---------------------analytical model-------------------------

throughput=[];
for n = 4:1:40 % nodes 
    fn = @(p)(p-1+(1-2*(1-2*p)/((1-2*p)*(CW_min+1)+p*CW_min*(1-(2*p)^m_max)))^(n-1));
    P = fzero(fn,[0,1]);
    tau = 2*(1-2*P)/((1-2*P)*(CW_min+1)+P*CW_min*(1-(2*P)^m_max));
    P_tr = 1-(1 - tau)^n;
    P_s = n*tau*(1-tau)^(n-1)/P_tr;
    S = P_s*Payload/((1/P_tr-1)*slot_time+P_s*Tsa+(1-P_s)*Tca);  % [Mbps]
    throughput=[throughput,S];
end
 
plot(5:5:40, throughput_Si,'b-o','LineWidth',1);
hold on
plot(4:1:40,throughput,'r--','LineWidth',1);
axis([4 40 10 20]);
xlabel('Number of nodes');
ylabel('Throughput(Mbps)');
legend('Simulation','analytical');
