function handles = LoadSingleImage(handles)

% Help for the Load Single Image module:
% Category: File Processing
%
% SHORT DESCRIPTION:
% Loads a single image, which will be used for all image cycles.
% *************************************************************************
% Note: for most purposes, you will probably want to use the Load Images
% module, not this one.
%
% Tells CellProfiler where to retrieve a single image and gives the image a
% meaningful name for the other modules to access.  This module processes 
% the input text string in one of two ways:
% (1) A string referring to a filename. In this case, the module only
% executes the first time through the pipeline, and thereafter the image
% is accessible to all subsequent cycles being processed. This is
% particularly useful for loading an image like an Illumination correction
% image to be used by the CorrectIllumination_Apply module. Note: Actually,
% you can load four 'single' images using this module.
% (2) A string referring to a regular expression. In this case, the module
% should be placed after a FileNameMetadata module and use the same regular
% expression applied in the FileNameMetadata module. It will execute each 
% cycle of the pipeline, matching the regular expression to the metadata
% previously measured. This is useful for when you have multiple images
% that need to be used once per cycle, but have a different name each
% cycle.
%
% Relative pathnames can be used. For example, on the Mac platform you
% could leave the folder where images are to be loaded as '.' to choose the
% default image folder, and then enter ../Imagetobeloaded.tif as the name
% of the file you would like to load in order to load the image from the
% directory one above the default image directory. Or, you could type
% .../AnotherSubfolder (note the three periods: the first is interpreted as
% a standin for the default image folder) as the folder from which images
% are to be loaded and enter the filename as Imagetobeloaded.tif to load an
% image from a different subfolder of the parent of the default image
% folder.  The above also applies for '&' with regards to the default
% output folder.
%
% NOTE: A LoadSingleImage module must be placed downstream of a 
% LoadImages module in order to work correctly.
%
% If more than four single images must be loaded, more than one Load Single
% Image module can be run sequentially. Running more than one of these
% modules also allows images to be retrieved from different folders.
%
% LoadImages can now open and read .ZVI files.  .ZVI files are Zeiss files
% that are generated by the microscope imaging software, Axiovision.  These
% images are stored with 12-bit precision.  Currently, this will not work
% with stacked or color images.
%
% See also LoadImages.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Please see the AUTHORS file for credits.
%
% Website: http://www.cellprofiler.org
%
% $Revision: 7853 $

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%

% Notes for PyCP
% (1) Right now, we do not explicitly state that users have the ability to
% load a different single image for each image group via a token obtained from FileNameMetaData using this module.
%  The two methods (exact match vs reg expression) also lead to two diff.
%  methods of processing in this module; the first populates the filelist
%  with the path and filename of the same image for every cycle, while the
%  other allows a different image to be loaded.  When the 'image grouping'
%  issue is worked out, it is probably best to have the user choose- do you
%  want to load one image for ALL cycles; do you want to load one image for
%  each image group (often image group = plate); this of
%  course depends on how we decide to handle image groups.
%  (2) Regardless of image grouping: users should be able to add additional
%  single images via '+ button' and initally only the path and first image
%  file & name should be visible (variables 2,3,4). When a user adds
%  another image, the additional 5,6 should pop up.

drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = This module loads one image for *all* cycles that will be processed. Typically, however, a different module (LoadImages) is used to load new sets of images during each cycle of processing.

%pathnametextVAR02 = Enter the path name to the folder where the images to be loaded are located.  Type period (.) for the default image folder, or type ampersand (&) for the default output folder.
Pathname = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%filenametextVAR03 = What image file do you want to load? Include the extension, like .tif
TextToFind{1} = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = What do you want to call that image?
%defaultVAR04 = OrigBlue
%infotypeVAR04 = imagegroup indep
ImageName{1} = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%filenametextVAR05 = What image file do you want to load? Include the extension, like .tif
TextToFind{2} = char(handles.Settings.VariableValues{CurrentModuleNum,5});

%textVAR06 = What do you want to call that image?
%defaultVAR06 = Do not use
%infotypeVAR06 = imagegroup indep
ImageName{2} = char(handles.Settings.VariableValues{CurrentModuleNum,6});

%filenametextVAR07 = What image file do you want to load? Include the extension, like .tif
TextToFind{3} = char(handles.Settings.VariableValues{CurrentModuleNum,7});

%textVAR08 = What do you want to call that image?
%defaultVAR08 = Do not use
%infotypeVAR08 = imagegroup indep
ImageName{3} = char(handles.Settings.VariableValues{CurrentModuleNum,8});

%filenametextVAR09 = What image file do you want to load? Include the extension, like .tif
TextToFind{4} = char(handles.Settings.VariableValues{CurrentModuleNum,9});

%textVAR10 = What do you want to call that image?
%defaultVAR10 = Do not use
%infotypeVAR10 = imagegroup indep
ImageName{4} = char(handles.Settings.VariableValues{CurrentModuleNum,10});

%%%VariableRevisionNumber = 4

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow;

% Make sure this module is placed after any LoadImages modules (since it
% needs the number of cycles to work properly)
if find(strcmp(handles.Settings.ModuleNames,'LoadImages'),1) > find(strcmp(handles.Settings.ModuleNames,ModuleName),1,'first')
    error(['Image processing was canceled in the ', ModuleName,' module. ',ModuleName,' must be placed downstream from a LoadImage module']);
end

%%% Determines which cycle is being analyzed.
isImageGroups = isfield(handles.Pipeline,'ImageGroupFields');
if ~isImageGroups
    SetBeingAnalyzed = handles.Current.SetBeingAnalyzed;
    NumberOfImageSets = handles.Current.NumberOfImageSets;
else
    SetBeingAnalyzed = handles.Pipeline.GroupFileList{handles.Pipeline.CurrentImageGroupID}.SetBeingAnalyzed;
    NumberOfImageSets = handles.Pipeline.GroupFileList{handles.Pipeline.CurrentImageGroupID}.NumberOfImageSets;
end

% Remove unused TextToFind and ImageName entries
idx = strcmp(TextToFind,'Do not use') | strcmp(ImageName,'Do not use');
TextToFind = TextToFind(~idx);
ImageName = ImageName(~idx);

% Substitute Metadata tokens into TextToFind (if found)
doTokensExist = false;
for n = 1:length(ImageName)
    [TextToFind{n},anytokensfound] = CPreplacemetadata(handles,TextToFind{n});
    doTokensExist =  doTokensExist || anytokensfound;
end

doFirstCycleOnly = (SetBeingAnalyzed == 1 & doTokensExist == 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FIRST CYCLE FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If there no tokens, we are dealing with a static image name and we only
% want to do this procedure once
% If tokens are present, we want to do this procedure for each cycle
% Regardless, we do this for the 1st image set
if doFirstCycleOnly || doTokensExist,
    %%% Get the pathname and check that it exists
    if strncmp(Pathname,'.',1)
        if length(Pathname) == 1
            Pathname = handles.Current.DefaultImageDirectory;
        else
            Pathname = fullfile(handles.Current.DefaultImageDirectory,strrep(strrep(Pathname(2:end),'/',filesep),'\',filesep),'');
        end
    elseif strncmp(Pathname, '&', 1)
        if length(Pathname) == 1
            Pathname = handles.Current.DefaultOutputDirectory;
        else
            Pathname = fullfile(handles.Current.DefaultOutputDirectory,strrep(strrep(Pathname(2:end),'/',filesep),'\',filesep),'');
        end
    else CPwarndlg('It is advisable to use RELATIVE path names, i.e. begin your path with either ''.'' or ''&''',[ModuleName,': Pathname warning'],'replace');
    end
    
    % Substitute Metadata tokens into Pathname (if found)
    Pathname = CPreplacemetadata(handles,Pathname);
    
    SpecifiedPathname = Pathname;
    if ~exist(SpecifiedPathname,'dir')
        error(['Image processing was canceled in the ', ModuleName, ' module because the directory "',SpecifiedPathname,'" does not exist. Be sure that no spaces or unusual characters exist in your typed entry and that the pathname of the directory begins with / (for Mac/Unix) or \ (for PC).'])
    end

    if isempty(ImageName)
        error(['Image processing was canceled in the ', ModuleName, ' module because you have not chosen any images to load.'])
    end

    for n = 1:length(ImageName)  
        %%% This try/catch will catch any problems in the load images module.
        try
            CurrentFileName = TextToFind{n};
            %%% The following runs every time through this module (i.e. for
            %%% every cycle).
            %%% Saves the original image file name to the handles
            %%% structure.  The field is named appropriately based on
            %%% the user's input, in the Pipeline substructure so that
            %%% this field will be deleted at the end of the analysis
            %%% batch.
            fieldname = ['Filename', ImageName{n}];
            handles.Pipeline.(fieldname) = CurrentFileName;
            fieldname = ['Pathname', ImageName{n}];
            handles.Pipeline.(fieldname) =  Pathname;

            FileAndPathname = fullfile(Pathname, CurrentFileName);
            LoadedImage = CPimread(FileAndPathname);
            %%% Saves the image to the handles structure.
            handles = CPaddimages(handles,ImageName{n},LoadedImage);
        catch
            CPerrorImread(ModuleName, n);
        end % Goes with: catch

        % Create a cell array with the filenames
        FileNames(n) = {CurrentFileName};
    end

    %%%%%%%%%%%%%%%%%%%%%%%
    %%% DISPLAY RESULTS %%%
    %%%%%%%%%%%%%%%%%%%%%%%
    drawnow

    ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
    if any(findobj == ThisModuleFigureNumber)
        % Remove uicontrols from last cycle
        delete(findobj(ThisModuleFigureNumber,'tag','TextUIControl'));
        
        if SetBeingAnalyzed == handles.Current.StartingImageSet
            CPresizefigure('','NarrowText',ThisModuleFigureNumber)
        end
        for n = 1:length(ImageName)
            drawnow;
            %%% Activates the appropriate figure window.
            currentfig = CPfigure(handles,'Text',ThisModuleFigureNumber);
            if iscell(ImageName)
                TextString = [ImageName{n},': ',FileNames{n}];
            else
                TextString = [ImageName,': ',FileNames];
            end
            uicontrol(currentfig,'style','text','units','normalized','fontsize',handles.Preferences.FontSize,'HorizontalAlignment','left','string',TextString,'position',[.05 .85-(n-1)*.15 .95 .1],'BackgroundColor',[.7 .7 .9],'tag','TextUIControl')
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% SAVE DATA TO HANDLES %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if doFirstCycleOnly
        % Since there's no need to re-load the same image multiple times,
        % replicate the filename/pathname measurement the neccesary number of 
        % times here
        for m = 1:NumberOfImageSets,
            for n = 1:length(ImageName),
                handles = CPaddmeasurements(handles, 'Image', ['FileName_', ImageName{n}], TextToFind{n}, m);
                handles = CPaddmeasurements(handles, 'Image', ['PathName_', ImageName{n}], Pathname, m);
            end
        end
    else
        % Add the measurement to the handles structure each cycle
        for n = 1:length(ImageName),
            handles = CPaddmeasurements(handles, 'Image', ['FileName_', ImageName{n}], TextToFind{n});
            handles = CPaddmeasurements(handles, 'Image', ['PathName_', ImageName{n}], Pathname);
        end
    end
end
