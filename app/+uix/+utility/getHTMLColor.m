function ColorOrderHTML = getHTMLColor(Colors)

ColorOrderHTML = {};
% Format the name with color using HTML color
for index = 1:size(Colors,1)
    ThisColor = Colors(index,:);
    if iscell(ThisColor)
        ThisColor = cell2mat(ThisColor);
    end
    ThisColor8Bit = floor(255*ThisColor);
    FormatStr = '<html><body bgcolor="#%02X%02X%02X" font color="#%02X%02X%02X" align="right">%s%s';
    ColorOrderHTML{end+1} = sprintf(FormatStr,ThisColor8Bit,ThisColor8Bit,repmat('-',1,50)); %#ok<AGROW>
end