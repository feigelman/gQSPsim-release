function [Results, StatusOK, Message, nFailedSims, job] = simulateVPatients_batch(taskObj, ItemModel, options, Results, job)
    nFailedSims = 0;
    StatusOK = true;
    Message = '';
    ParallelCluster = options.ParallelCluster;
    c = parcluster(ParallelCluster);
    
    
%     
%     p = gcp('nocreate');
% %     p = gcp;

%     if isempty(p)
%         p = parpool(ParallelCluster); %, 'AutoAddClientPath', true, 'AttachedFiles', UDF_files);
%         p = parpool;
%     elseif ~strcmp(p.Cluster.Profile, taskObj.Session.ParallelCluster)
%         delete(gcp('nocreate'))
%         p = parpool(taskObj.Session.ParallelCluster, ...
%          'AttachedFiles', taskObj.Session.UserDefinedFunctionsDirectory);
%     end
% 
%     addAttachedFiles(p, UDF_files);


    q = parallel.pool.DataQueue;
    progress = 0;
%     listener = afterEach(q, @() updateWaitBar(options.WaitBar, ItemModel) );
    ParamValues_in = options.Pin;

    if ~isempty(ParamValues_in)
        Names = options.paramNames;
        Values = ParamValues_in;
    else
        Names = ItemModel.Names;
        Values = ItemModel.Values;
    end

%     nSim = 0;
%     numlabs = p.NumWorkers;
%     blockSize = max(100,ceil(ItemModel.nPatients / numlabs));
%     
%     for labindex = 1:numlabs
%         block = blockSize*(labindex-1) + (1:blockSize);
%         block = block(block<=ItemModel.nPatients);
%         if isempty(block)
%             break
%         end
% %                 F(labindex) = parfeval(p, @parBlock, 2, block, Names, Values, taskObj, Results);
%         F(labindex) = parfeval(p, @parBlock, 3, block, Names, Values, taskObj, Results);
% 
% %                 Results = parBlock(block, Names, Values, taskObj, Results);
%     end
%     wait(F);
%     try         
%         [Results, StatusOK, Message] = fetchOutputs(F);
% 
%     catch err
%         warning(err.message)
%     end
%     
    block = 1:ItemModel.nPatients;



    function updateWaitBar(WaitBar, ItemModel)
%         nSim = nSim + 1;
        progress = progress + 1;
        % update wait bar
        StatusOK = true;
    %         fprintf('jj = %d\n', jj)
        if ~isempty(WaitBar)
            StatusOK = uix.utility.CustomWaitbar(progress/ItemModel.nPatients, WaitBar, sprintf('Simulating vpatient %d/%d', nSim, ItemModel.nPatients));
            if ~StatusOK
                cancel(F)
                delete(listener)
            end
        end

    end

    

end

