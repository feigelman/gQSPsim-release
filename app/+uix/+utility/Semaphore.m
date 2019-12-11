classdef Semaphore < handle
    %SEMAPHORE A blocking event handler
    %   Matlab's waitfor() command requires a figure. This makes it a bit
    %   easier to interface with so the code isn't as unusual.
    
    properties(Access = private)
        Figure
    end
    methods(Static, Access = private)
        function fig = operation(i)
            persistent unallocatedfigures;
            if i == -1 % return a figure
                if isempty(unallocatedfigures)
                    % Allocate another one
                    fig = figure('Visible', 'off');
                else
                    fig = unallocatedfigures(1);
                    unallocatedfigures = unallocatedfigures(2:end);
                end
            else % release a figure
                unallocatedfigures = [unallocatedfigures, i];
                fig = -1;
            end
        end
    end
    methods
        function obj = Semaphore()
            obj.Figure = obj.operation(-1);
            obj.lock();
        end
        function obj = release(obj)
            set(obj.Figure, 'UserData', false);
        end
        function obj = lock(obj)
            set(obj.Figure, 'UserData', true);
        end
        function obj = wait(obj)
            waitfor(obj.Figure, 'UserData', false);
        end
        function obj = delete(obj)
            obj.operation(obj.Figure);
        end
    end
end

