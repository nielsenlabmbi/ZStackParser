function ZStackParser(isSilent)
    if ~exist('isSilent','var')
        isSilent = 1;
    end
    
    [filename,pathname] = uigetfile( ...
        {'*.sbx','Scanbox image files (*.sbx)'; '*.*', 'All Files (*.*)'},...
        'Pick the first and last files of the stack','Z:\2P\Ferret 2P\Ferret 2P data','MultiSelect', 'on');

    [~,filenameStart,~] = fileparts(filename{1});
    [~,filenameEnd,~] = fileparts(filename{2});

    [animal,unit,exptStart] = splitDelimitedExptId(filenameStart);
    [~,~,exptEnd] = splitDelimitedExptId(filenameEnd);
    
    stackPrefix = [animal '_' sprintf('%03d',unit)];
    range = [exptStart exptEnd];
    
    numFiles = diff(range) + 1;

    if ~isSilent
        h = waitbar(0);
        f = figure('position',[18   541   560   420],'name','Calculating stack');
    end
    
    frame = zeros(512,796,numFiles,3);

    for i=1:numFiles
        fileName = [pathname stackPrefix '_'  sprintf('%03d',range(1) + i - 1)];
        load(fileName);

        allFrames = sbxread(fileName,0,info.config.frames);
        avg = mean(allFrames,4);

        frame(:,:,i,1) = squeeze(avg(2,:,:))/max(max(max(squeeze(avg(2,:,:)))));
        frame(:,:,i,2) = squeeze(avg(1,:,:))/max(max(max(squeeze(avg(1,:,:)))));
        frame(:,:,i,3) = zeros(size(squeeze(avg(2,:,:))));

        if (i==1)
            imwrite(squeeze(frame(:,:,i,:)), [pathname stackPrefix '_zConstructed.tiff'], 'tif', 'WriteMode', 'overwrite','Compression', 'none');
        else
            imwrite(squeeze(frame(:,:,i,:)), [pathname stackPrefix '_zConstructed.tiff'], 'tif', 'WriteMode', 'append','Compression', 'none');
        end

        if ~isSilent
            waitbar(i/numFiles,h,['Averaging at height ' num2str(info.config.zpos)]);
            imshow(squeeze(frame(:,:,i,:))); title(['Averaging at height ' num2str(info.config.zpos)]);
        end
    end

    if ~isSilent
        close(h); close(f);
    end

    save([pathname stackPrefix '_zConstructed.mat'],'frame');
end

function [animal,unit,expt] = splitDelimitedExptId(exptID)
	values 	= textscan(exptID, '%s%d%d', 'delimiter', '_');
	animal 	= values{1}{1};
	unit 	= values{2};
	expt 	= values{3};
end


