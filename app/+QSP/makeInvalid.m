function str = makeInvalid(str)
if isnumeric(str)
    str = num2str(str);
end
validateattributes(str,{'char'},{});
str = sprintf('**INVALID** %s',str);

% str = sprintf('<html><font color="red">%s (INVALID)</font></html>',str);

