function [out,ftie_out,iu] = scuc_accelerateSolve(model,ftie_avg,lamda,Rho,iu)
%% insensitive unit struct
iu.onoff_old;       % �����ϴε���״̬ 
iu.invar_times;     % ����״̬�������
iu.fix_units;       % ״̬�̶�����
iu.insens_times;     % 
% iu.onoff_old = zeros(scuc_in.T,scuc_in.Ng);  % �����ϴε���״̬ 
% iu.invar_times = zeros(1,scuc_in.Ng);        % ����״̬�������
% iu.fix_units = false(1,scuc_in.Ng);          % ״̬�̶�����
[T,Ng] = size(iu.onoff_old);
%% fix unit status
for g =1:Ng
    if iu.fix_units(g)==1
        model.Constraints = [model.Constraints, (model.Variable.onoff(:,g) == iu.onoff_old(:,g)):'fix unit status'];
        iu.fix_units(g)=2;
    end
end
%% objective
model.Objective = model.Objective +...
    sum(sum(lamda.*(model.Variable.ftie-ftie_avg)))+...
    sum(sum(Rho*0.5*(model.Variable.ftie-ftie_avg).*(model.Variable.ftie-ftie_avg)));
%% solve
Ops = sdpsettings('solver','gurobi','usex0',1,'verbose',0,'showprogress',0);
Ops.gurobi.MIPGap=0.0002;
%         Ops.gurobi.MIPGapAbs=1.0;
Ops.gurobi.OptimalityTol = 0.0002;
%         Ops.gurobi.FeasRelaxBigM   = 1.0e10;
Ops.gurobi.DisplayInterval = 20;
diagnose = optimize(model.Constraints,model.Objective,Ops); 
% check(Constraints);
if diagnose.problem ~= 0
    error(yalmiperror(diagnose.problem));
end
%% read values of variables
%%--------------------------- wind power & PV -----------------------------
out.Pwind= value(model.Variable.Pwind);    %% output of wind power 
%%--------------------------- thermal unit --------------------------------
out.Pg=  value(model.Variable.Pg);
out.onoff = value(model.Variable.onoff);
out.startup  = value(model.Variable.startup);
out.shutdown = value(model.Variable.shutdown);
%%---------------------------- tie lines ----------------------------------
out.ftie = value(model.Variable.ftie);
out.Ftie = value(model.Variable.Ftie);
out.Objective =value(model.Objective);
out.ThermalCost = value(model.Variable.ThermalCost);
out.WindCur = value(model.Variable.WindCur);
ftie_out = value(model.Variable.ftie);
%% update onoff_old, invar_times
for g =1:Ng
    if iu.fix_units(g)== 0
        if all(out.onoff(:,g) == iu.onoff_old(:,g))
            iu.invar_times(g) = iu.invar_times(g)+1;
            if iu.invar_times(g) >= iu.insens_times
                iu.fix_units(g) = 1;
            end
        else
            iu.onoff_old(:,g) = out.onoff(:,g);
            iu.invar_times(g) = 1;
        end
    end
end 
