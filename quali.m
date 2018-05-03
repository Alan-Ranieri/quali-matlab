function quali()
    mainInterface = startMainInterface();
end

function mainFig = startMainInterface()
    % Make program full screen
    screenSize = get(0, 'ScreenSize');
    mainInterfaceColor = [0, 0, 0];
    
    mainFig = figure('Position', screenSize,...
        'MenuBar', 'none',...
        'NumberTitle', 'off',...
        'Name', ['Qualitative Analysis of Lung Images - 0.0.0dev0 -'...
                 ' Matlab Version'],...
        'Color', mainInterfaceColor,...
        'Resize', 'Off',...
        'WindowButtonMotionFcn', @mouseMove,...
        'WindowScrollWheelFcn', @refreshSlicePosition);
    
  informationAxes = axes('Parent', mainFig,...
      'Units', 'Normalized',...
      'Position', [0, 0.06, 1, 0.85],...
      'Color', [0, 0, 0],...
      'XTickLabel', [],...
      'YTickLabel', [],...
      'Xcolor', [0, 0, 0],...
      'Ycolor', [0, 0, 0],...
      'Tag', 'informationAxes');
  
  imageAxes = axes('Parent', mainFig,...
        'Units', 'Normalized',...
        'Position', [0.15, 0.06, 0.7, 0.85],...
        'Color', [0, 0, 0],...
        'XTickLabel', [],...
        'YTickLabel', [],...
        'Xcolor', [0, 0, 0],...
        'Ycolor', [0, 0, 0],...
        'Tag', 'imageAxes');

    
    startAxesMetadataInfo(informationAxes);
    
    % Upper Panel with all options
    mainPanel = uipanel('Parent', mainFig,...
        'Units', 'Normalized',...
        'Position', [0, 0.915, 1, 0.08],...
        'Title', '',...
        'BackGroundColor', [0.1, 0.1, 0.1]);
    
    uicontrol('Parent', mainPanel,...
        'Units', 'Normalized',...
        'Position', [0.01, 0.2, 0.08, 0.6],...
        'String', 'Import Dicom',...
        'BackGroundColor', [0.1, 0.1, 0.1],...
        'ForeGroundColor', [54/255, 189/255, 1],...
        'FontWeight', 'Bold',...
        'FontSize', 14,...
        'Callback', @openImage);
    
        uicontrol('Parent', mainPanel,...
        'Units', 'Normalized',...
        'Position', [0.1, 0.2, 0.08, 0.6],...
        'String', 'Import Mask',...
        'BackGroundColor', [0.1, 0.1, 0.1],...
        'ForeGroundColor', [54/255, 189/255, 1],...
        'FontWeight', 'Bold',...
        'FontSize', 14,...
        'Enable', 'Off',...
        'Tag', 'importMaskButton',...
        'Callback', @openMask);
    
    %Start data handles
    handles.data = '';
    
    handles.gui = guihandles(mainFig);
    guidata(mainFig, handles);
end

function startAxesMetadataInfo(imageAxes)
    text(imageAxes, 0.5, 0.98,...
        '',...
        'Color', 'White',...
        'HorizontalAlignment', 'center',...
        'FontSize', 14,...
        'Tag', 'patientNameTextObject');
    
    text(imageAxes, 0, 0.01,...
        '',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSliceNumber');
    
        
    text(imageAxes, 0, 0.94,...
        'Image Dimensions: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textImageDimensions');
    
    text(imageAxes, 0, 0.05,...
        'Pixel Value: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textPixelValue');

    text(imageAxes, 0, 0.90,...
        'Slice Thickness',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSliceThickness');
    
    text(imageAxes, 0, 0.09,...
        'Space Btw Slices: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSpaceBetweenSlices');
    
    text(imageAxes, 0, 0.98,...
        'Slice Location: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSliceLocation');
        
    text(imageAxes, 0.9, 0.98,...
        'Window Length: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14);   
    
    text(imageAxes, 0.9, 0.94,...
        'Window Width: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             CALLBACKS                                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function openImage(hObject, ~)
    % Import Images
    handles = guidata(hObject);
    if isfield(handles.data, 'lastVisitedFolder')
        rootPath = uigetdir(handles.data.lastVisitedFolder,...
            'Select a folder with Dicom images');
    else
        rootPath = uigetdir('.', 'Select a folder with Dicom images');
    end
    
    if rootPath
        handles.data.lastVisitedFolder = rootPath;
        handles.data.imageCoreInfo = importDicoms(rootPath);
        
        % Check if any image was found
        if ~isempty(handles.data.imageCoreInfo)
            %Show first Slice
            showImageSlice(handles.gui.imageAxes,...
                handles.data.imageCoreInfo.matrix(:, :, 1));
            
            startScreenMetadata(handles,...
                handles.data.imageCoreInfo.metadata{1})
            
            % Save imported data
            guidata(hObject, handles)
            
            % Enable controls
            set(handles.gui.importMaskButton, 'Enable', 'On')
        end
        
    end
end

function openMask(hObject, ~)
    handles = guidata(hObject);
    if isfield(handles.data, 'lastVisitedFolder')
        [fileName, pathName] = uigetfile('*.hdr;*.nrrd',...
            'Select the file containing the masks',...
            handles.data.lastVisitedFolder);
    else
        [fileName, pathName] = uigetfile('*.hdr;*.nrrd',...
            'Select the file containing the masks');
    end
    
    if ~isempty(fileName)
        rootPath = [pathName fileName];
        handles.data.imageCoreInfo.masks = importMasks(rootPath);
        handles.data.lastVisitedFolder = rootPath;
        
        % Save imported mask
        guidata(hObject, handles)
    end
    
end

function mouseMove(hObject, ~)
    handles = guidata(hObject);
    if isfield(handles.data, 'imageCoreInfo')
        imageAxes = handles.gui.imageAxes;
        refreshPixelPositionInfo(handles, imageAxes);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             UTILS                                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function showImageSlice(axisObject, imageSlice)
    axes(axisObject);
    imagesc(imageSlice);
    colormap(gray)
    set(axisObject, 'XtickLabel', [])
    set(axisObject, 'YtickLabel', [])
    
end

function updateSliceNumberText(textObject, sliceNumber, nSlices)
    set(textObject, 'String', sprintf('%d / %d', sliceNumber, nSlices));
end

function updateSliceLocationText(textObject, sliceLocation)
    set(textObject, 'String', sprintf('Slice Location: %.2f',...
        sliceLocation));
end

function startScreenMetadata(handles, metadata)
    % Show Slice Number
    updateSliceNumberText(handles.gui.textSliceNumber, 1,...
        size(handles.data.imageCoreInfo.matrix, 3))
    
    updateSliceLocationText(handles.gui.textSliceLocation,...
        metadata.SliceLocation)
    
    % Show Image Dimensions
    set(handles.gui.textImageDimensions, 'String',...
        sprintf('Image Dimension: %d x %d', metadata.Rows,...
        metadata.Columns));
    
    if isfield(metadata, 'SpaceBetweenSlices')
        set(handles.gui.textSpaceBetweenSlices, 'String',...
            sprintf('Space Btw Slices: %.2f', metadata.SpaceBetweenSlices));
    end
    
    set(handles.gui.textSliceThickness, 'String',...
        sprintf('Slice Thickness: %.2f', metadata.SliceThickness));
end

function refreshPixelPositionInfo(handles, mainAxes)

if isfield(handles, 'data')
    C = get(mainAxes,'currentpoint');

    xlim = get(mainAxes,'xlim');
    ylim = get(mainAxes,'ylim');

    row = round(C(1));
    col = round(C(1, 2));

    %Check if pointer is inside Navigation Axes.
    outX = ~any(diff([xlim(1) C(1,1) xlim(2)])<0);
    outY = ~any(diff([ylim(1) C(1,2) ylim(2)])<0);
    if outX && outY
        %Get the current Slice
        currentSlicePositionString = get(handles.gui.textSliceNumber,...
            'String');
        tempSlicePosition = regexp(currentSlicePositionString, '/',...
            'split');
        slicePosition = str2double(tempSlicePosition(1));

        currentSlice = handles.data.imageCoreInfo.matrix(:, :,...
            slicePosition);

        pixelValue = currentSlice(col, row);

        set(handles.gui.textPixelValue, 'String',...
            sprintf('Pixel Value = %.2f', double(pixelValue)))
    else
        set(handles.gui.textPixelValue, 'String',...
            sprintf('Pixel Value = -'))
    end

end
end

function newSlicePosition = getSlicePosition(slicePositionString, direction)
    tempSlicePosition = regexp(slicePositionString, '/', 'split');

    if direction > 0
        newSlicePosition = str2double(tempSlicePosition(1)) + 1;
    else
        newSlicePosition = str2double(tempSlicePosition(1)) - 1;
    end
end

function refreshSlicePosition(hObject, eventdata)

slicePositionPlaceHolder = '%d / %d';

handles = guidata(hObject);

if isfield(handles, 'data')

    nSlices = size(handles.data.imageCoreInfo.matrix, 3);

    currentSlicePosition = get(handles.gui.textSliceNumber, 'String');

    %Get the new slice position based on the displayed values using regexp
    newSlicePosition = getSlicePosition(currentSlicePosition,...
        eventdata.VerticalScrollCount);

    %Make sure that the slice number return to 1 if it is bigger than the
    %number of slices
    newSlicePosition = mod(newSlicePosition, nSlices);

    %Make sure that the slice number return to nSlices if it is smaller than the
    %number of slices
    if ~newSlicePosition && eventdata.VerticalScrollCount < 0
        newSlicePosition = nSlices;
    elseif ~newSlicePosition && eventdata.VerticalScrollCount >= 0 %%% -- INFO -- matlab has some hard time with the scroll of my laptop, in this case VerticalScrollCount == 0, it get an error latter in this function and this is error realy I need to restart matlab. I changed > to >=
        newSlicePosition = 1;
    end

    %Refresh slice position information.
    set(handles.gui.textSliceNumber, 'String',...
        sprintf(slicePositionPlaceHolder, newSlicePosition, nSlices));
  
    showImageSlice(handles.gui.imageAxes,...
        handles.data.imageCoreInfo.matrix(:, :, newSlicePosition));
    

    %Refresh pixel value information.
    refreshPixelPositionInfo(handles, handles.gui.imageAxes)
    
    %Refresh Slice Location information.
    updateSliceLocationText(handles.gui.textSliceLocation,...
        handles.data.imageCoreInfo.metadata{newSlicePosition}.SliceLocation);

    guidata(hObject, handles)
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             LOG FRAME                            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figObject = createLogFrame()
    %disply calculation log.
    figObject = figure('Units', 'Normalized',...
        'Position', [0.3, 0.4, 0.4, 0.2],...
        'Toolbar', 'None',...
        'Menubar', 'None',...
        'Color', 'black',...
        'Name', 'Log',...
        'NumberTitle', 'Off',...
        'Resize', 'Off');
end

function displayLog(figObj, msg, clearAxes)
   if clearAxes
       cla
   else
       ax = axes('Parent', figObj, 'Visible', 'Off');
       axes(ax)
    end

    text(0.5, 0.5, msg, 'Color', 'white', 'HorizontalAlignment',...
    'center', 'FontSize', 14)

    drawnow
end
