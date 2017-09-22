function [] = GenerateHogDescriptors(opts,descriptor_opts)

fprintf('Building Hog Descriptors\n\n');

%% parameters
descriptor_flag=1;
maxImageSize = descriptor_opts.maxImageSize;
cellSize = descriptor_opts.cellSize;

try
    descriptor_opts2=getfield(load([opts.globaldatapath,'/',descriptor_opts.name,'_settings']),'descriptor_opts'); % 加载A文件夹中的B文件
    if(isequal(descriptor_opts,descriptor_opts2))
        descriptor_flag=0;
        disp('descriptor has already been computed for this settings');
    else
        disp('Overwriting descriptor with same name, but other descriptor settings !!!!!!!!!!');
    end
end

if(descriptor_flag)   % 如果hog特征没有被计算
    
    %% load image
    load(opts.image_names);           % load image in data set
    nimages = opts.nimages;           % number of images in data set
    
    for f = 1:nimages
        
        I = load_image([opts.imgpath,'/', image_names{f}]); % 调用函数，将每一张图片变为灰度图（像素取值归一化[0,1]）
        
        [hgt, wid] = size(I);  % 返回图像的行和列，即高和宽！！！
        if min(hgt,wid) > maxImageSize  % 图片大小预处理
            I = imresize(I, maxImageSize/min(hgt,wid), 'bicubic');
            fprintf('Loaded %s: original size %d x %d, resizing to %d x %d\n', ...
                image_names{f}, hgt, wid, size(I,2), size(I,1));
            [hgt,wid] = size(I);
        end
        
       %% calculate blockNum
        
        % 生成图片划分的block（每行（或每列）block数目为每行（或每列）cell数目-1）
        [gridX,gridY] = meshgrid(1+cellSize:cellSize:(wid-mod(wid,cellSize)+1-cellSize), 1+cellSize:cellSize:(hgt-mod(hgt,cellSize)+1-cellSize)); % 计算行、列各有多少block
  
        fprintf('Processing %s: wid %d, hgt %d, grid size: %d x %d, %d blocks\n', ...
            image_names{f}, wid, hgt, size(gridX,2), size(gridX,1),  numel(gridX));
        
       %% find HOG descriptors
        hogArr = find_hog_grid(I, cellSize); % 计算 block 的 Hog 特征
        
        features.data = hogArr;
        features.x = gridX(:);  % 保存 block 中心，后面会在 CompilePyramid.m 中使用
        features.y = gridY(:);
        features.wid = wid;
        features.hgt = hgt;
        features.cellSize = cellSize;   % cell大小
        
        image_dir = sprintf('%s/%s/',opts.localdatapath,num2string(f,3)); % location descriptor
        save ([image_dir,'/','hog_features'], 'features');           % save the descriptors
        
        fprintf('The %d th image finished...\n',f);
       
    end % for
    save ([opts.globaldatapath,'/',descriptor_opts.name,'_settings'],'descriptor_opts');      % save the settings of descriptor in opts.globaldatapath
end % if

end% function
