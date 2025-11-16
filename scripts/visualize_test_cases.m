function visualize_test_cases(varargin)
% visualize_test_cases
% Loads all .mat files in Test_case/ and creates basic visualizations
% for numeric arrays it finds at the top level or one level inside structs.
%
% Usage:
%   - From MATLAB: run('scripts/visualize_test_cases.m')  % then call visualize_test_cases
%   - Call to process all test cases: visualize_test_cases
%   - Call to process specific files: visualize_test_cases('Test_case/T1.mat', 'Test_case/T2.mat')
%
% Outputs:
%   - Saves PNG figures to output/plots/
%
% Notes:
%   - This is a generic visualizer meant to work without prior knowledge
%     of variable names. Customize the detection logic if needed.

    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    testCaseDir = fullfile(projectRoot, 'Test_case');
    outputDir   = fullfile(projectRoot, 'output', 'plots');
    initialSetupPath = fullfile(projectRoot, 'Initial_setup.mat');

    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    % Build list of .mat paths to process:
    matPaths = {};
    if nargin == 0
        d = dir(fullfile(testCaseDir, '*.mat'));
        if isempty(d)
            fprintf('[INFO] No .mat files found in %s\n', testCaseDir);
        else
            matPaths = arrayfun(@(x) fullfile(x.folder, x.name), d, 'UniformOutput', false);
        end
    else
        for a = 1:nargin
            p = varargin{a};
            if ischar(p) || isstring(p)
                ap = char(p);
                if ~contains(ap, filesep)
                    ap = fullfile(testCaseDir, ap);
                end
                if isfile(ap)
                    matPaths{end+1} = ap; %#ok<AGROW>
                else
                    warning('[WARN] Path not found or not a file: %s', ap);
                end
            else
                warning('[WARN] Ignoring non-string argument at position %d', a);
            end
        end
    end

    for k = 1:numel(matPaths)
        matPath = matPaths{k};
        fprintf('[INFO] Loading %s\n', matPath);
        S = load(matPath);
        try
            [~, base, ext] = fileparts(matPath);
            figs = plot_variables_from_struct(S, [base, ext]);
            save_figures(figs, outputDir, strip_extension([base, ext]));
            close_figs(figs);
        catch ME
            warning('[WARN] Failed to visualize %s: %s', matPath, ME.message);
        end
    end

    if nargin == 0 && isfile(initialSetupPath)
        fprintf('[INFO] Loading %s\n', initialSetupPath);
        S0 = load(initialSetupPath);
        try
            figs0 = plot_variables_from_struct(S0, 'Initial_setup.mat');
            save_figures(figs0, outputDir, 'Initial_setup');
            close_figs(figs0);
        catch ME
            warning('[WARN] Failed to visualize Initial_setup.mat: %s', ME.message);
        end
    end

    fprintf('[DONE] Plots saved to: %s\n', outputDir);
end

function figs = plot_variables_from_struct(S, sourceName)
% Create figures for numeric variables found in struct S (top-level),
% and one level deeper for struct fields.

    figs = [];
    varNames = fieldnames(S);
    for i = 1:numel(varNames)
        vname = varNames{i};
        v = S.(vname);

        if isnumeric(v)
            figs(end+1) = plot_numeric_array(v, sprintf('%s — %s', sourceName, vname)); %#ok<AGROW>
        elseif isstruct(v)
            innerNames = fieldnames(v);
            for j = 1:numel(innerNames)
                iname = innerNames{j};
                try
                    iv = v.(iname);
                    if isnumeric(iv)
                        figs(end+1) = plot_numeric_array(iv, sprintf('%s — %s.%s', sourceName, vname, iname)); %#ok<AGROW>
                    end
                catch
                    % Skip inaccessible fields
                end
            end
        elseif istable(v)
            try
                numericVars = varfun(@isnumeric, v, 'OutputFormat', 'uniform');
                if any(numericVars)
                    figs(end+1) = plot_table_numeric(v(:, numericVars), sprintf('%s — %s (table)', sourceName, vname)); %#ok<AGROW>
                end
            catch
                % varfun may fail on some MATLAB versions; skip silently
            end
        else
            % Non-numeric types are skipped
        end
    end

    if isempty(figs)
        % Provide at least one figure indicating no numeric content
        f = figure('Visible','off');
        annotation('textbox',[0 0 1 1], 'String', sprintf('No numeric variables found in %s', sourceName), ...
                   'HorizontalAlignment','center', 'VerticalAlignment','middle', 'FontSize', 14, 'EdgeColor','none');
        figs = f;
    end
end

function f = plot_numeric_array(A, titleText)
% Plot numeric arrays in a reasonable default way:
% - 1D vector: line plot vs index
% - 2D matrix: plot up to first 3 columns vs index
% - 3D+: plot the first slice reduced along dimensions if possible

    f = figure('Visible','off');
    try
        if isvector(A)
            plot(A, 'LineWidth', 1.2);
            xlabel('Index');
            ylabel('Value');
        elseif ismatrix(A)
            nCols = size(A, 2);
            maxCols = min(3, nCols);
            plot(A(:, 1:maxCols), 'LineWidth', 1.2);
            xlabel('Index');
            ylabel('Value');
            legend(compose('Col %d', 1:maxCols), 'Location', 'best');
        else
            % Higher dimensional: try to squeeze and plot first vector-like dimension
            B = squeeze(A);
            if isvector(B)
                plot(B, 'LineWidth', 1.2);
                xlabel('Index');
                ylabel('Value');
            elseif ismatrix(B)
                nCols = size(B, 2);
                maxCols = min(3, nCols);
                plot(B(:, 1:maxCols), 'LineWidth', 1.2);
                xlabel('Index');
                ylabel('Value');
                legend(compose('Col %d', 1:maxCols), 'Location', 'best');
            else
                imagesc(B);
                colorbar;
                xlabel('Dim 2');
                ylabel('Dim 1');
            end
        end
        grid on;
        title(titleText, 'Interpreter', 'none');
    catch
        close(f);
        rethrow(lasterror); %#ok<LERR>
    end
end

function f = plot_table_numeric(T, titleText)
% Plot each numeric variable in table T as a subplot
    f = figure('Visible','off');
    try
        varNames = T.Properties.VariableNames;
        n = numel(varNames);
        n = min(n, 6); % cap to keep figure readable
        rows = ceil(n/2);
        cols = 2;
        for i = 1:n
            subplot(rows, cols, i);
            v = T.(varNames{i});
            if isvector(v)
                plot(v, 'LineWidth', 1.2);
                xlabel('Index');
                ylabel(varNames{i});
            elseif ismatrix(v)
                nCols = size(v, 2);
                mCols = min(3, nCols);
                plot(v(:, 1:mCols), 'LineWidth', 1.2);
                xlabel('Index');
                ylabel(varNames{i});
                legend(compose('Col %d', 1:mCols), 'Location', 'best');
            else
                imagesc(v);
                colorbar;
                xlabel('Dim 2');
                ylabel('Dim 1');
            end
            grid on;
            title(varNames{i}, 'Interpreter', 'none');
        end
        sgtitle(titleText, 'Interpreter', 'none');
    catch
        close(f);
        rethrow(lasterror); %#ok<LERR>
    end
end

function save_figures(figs, outDir, baseName)
% Save each figure handle in figs to PNG files with systematic names.
    timestamp = datestr(now, 'yyyymmdd_HHMMSS_FFF');
    for idx = 1:numel(figs)
        fname = sprintf('%s_%s_%02d.png', baseName, timestamp, idx);
        fpath = fullfile(outDir, fname);
        try
            exportgraphics(figs(idx), fpath, 'Resolution', 150);
            fprintf('[SAVE] %s\n', fpath);
        catch
            try
                print(figs(idx), fpath, '-dpng', '-r150');
                fprintf('[SAVE-FALLBACK] %s\n', fpath);
            catch ME
                warning('[WARN] Failed to save figure %d for %s: %s', idx, baseName, ME.message);
            end
        end
    end
end

function close_figs(figs)
    for idx = 1:numel(figs)
        try
            close(figs(idx));
        catch
            % ignore
        end
    end
end

function s = strip_extension(name)
    [~, s, ~] = fileparts(name);
end
