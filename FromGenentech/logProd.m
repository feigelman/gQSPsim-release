function [sig,order] = logProd(X)

% compute the column-wise product of a matrix of small numbers
% return the significant digits and order of magnitude of the product

order = floor(log10(X));
sig = X ./ 10.^order;

sig = prod(sig,1);
order = sum(order,1);
