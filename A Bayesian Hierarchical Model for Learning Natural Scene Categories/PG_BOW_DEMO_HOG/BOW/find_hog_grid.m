function hog_arr = sp_find_hog_grid(I, cell_size)

%伽马校正
I = sqrt(I);     

%下面是求边缘
fx = [-1 0 1];        % 定义水平模板
fy = -fx';            % 定义竖直模板
Ix = imfilter(I,fx,'replicate');    % 水平边缘
Iy = imfilter(I,fy,'replicate');    % 竖直边缘
I_mag = sqrt(Ix.^2+Iy.^2);          % 边缘强度，权值
I_theta = Iy./Ix;            % 边缘斜率，有些为inf,-inf,nan，其中nan需要再处理一下

I_theta(find(isnan(I_theta))) = 0; % 用0替代非法的结果，因为有些地方的梯度值为inf


%下面是求cell
[hgt, wid] = size(I);     % 行对应高，列对应宽
step = cell_size;         % 步长
orient = 9;               % 方向直方图的方向个数
jiao = 360/orient;        % 每个方向包含的角度数
Cell = cell(1,1);         % 所有的角度直方图,cell是可以动态增加的，所以先设置了一个                     

jj = 1;
for i = 1:step:hgt-mod(hgt,step)          % 如果处理的hgt/step不是整数，是整数也可以，因为mod求余为0
    ii = 1;
    for j = 1:step:wid-mod(wid,step)       % 注释同上
        tmpx = Ix(i:i+step-1,j:j+step-1);  % 取一个元胞梯度Gx
        tmped = I_mag(i:i+step-1,j:j+step-1);  % 取一个元胞梯度值
        tmped = tmped / sum(sum(tmped));        % 局部边缘强度归一化，即加权权值
        tmp_theta = I_theta(i:i+step-1,j:j+step-1); % 取一个元胞的梯度方向
        Hist = zeros(1,orient);         % 当前step*step像素块统计角度直方图,就是cell
        for p = 1:step
            for q = 1:step
                ang = atan(tmp_theta(p,q));    % atan求的是[-90 90]度之间
                ang = mod(ang*180/pi,360);    % 全部变正，-90变270
                if tmpx(p,q) < 0              % 根据x方向确定真正的角度
                    if ang < 90               % 如果是第一象限
                        ang = ang+180;        % 移到第三象限
                    end
                    if ang > 270              %如果是第四象限
                        ang = ang-180;        %移到第二象限
                    end
                end
                ang = ang + 0.0000001;          %防止ang为0
                Hist(ceil(ang/jiao)) = Hist(ceil(ang/jiao)) + tmped(p,q);   %ceil向上取整，使用边缘强度加权
            end
        end
        % Hist = Hist/sum(Hist);   % 方向直方图归一化，这一步可以没有，因为是组成block以后再进行归一化就可以
        Cell{ii,jj} = Hist;       % 放入Cell中
        ii = ii + 1;                % 针对Cell的y坐标循环变量
    end
    jj = jj + 1;                    % 针对Cell的x坐标循环变量
end

% 下面是求feature, 2*2个cell合成一个block,没有显式的求block
[m, n] = size(Cell);
feature = cell(1,(m-1)*(n-1)); % 步长为step，故滑动m-1（或n-1）次
for i = 1:m-1
   for j = 1:n-1           
        f = [ Cell{i,j}(:)', Cell{i,j+1}(:)', Cell{i+1,j}(:)', Cell{i+1,j+1}(:)'];  % 4*9=36维
        f = f./sum(f); % 归一化
        feature{(i-1)*(n-1)+j} = f;
   end
end

len = length(feature);
hog_arr = [];
for i = 1:len
    hog_arr = [hog_arr;feature{i}(:)'];   % hog_arr即为所求hog特征
end