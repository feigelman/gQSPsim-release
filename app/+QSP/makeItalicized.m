function str = makeItalicized(str)
if isnumeric(str)
    str = num2str(str);
end
validateattributes(str,{'char'},{});
str = sprintf('<html><i><font color="gray">%s</font>',str);
