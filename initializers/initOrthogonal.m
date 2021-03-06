%% --------------------------initOrthogonal.m-----------------------------

% Intializer proposed in Algorithm 1 of the Null Initializer paper. This 
% method throws out the measurements with large magnitude.  The remaining 
% measurement vectors are nearly orthogonal to the unknown signal.  The 
% signal is then approximated by finding a vector that is orthogonal to 
% these remaining measurment vectors.  This requires computing the trailing
% eigenvector (corresponding to the smallest eigenvalue) of a large matrix.
%  
%% I/O
%  Inputs:
%     A:  m x n matrix (or optionally a function handle to a method) that
%         returns A*x.
%     At: The adjoint (transpose) of 'A'. If 'A' is a function handle, 'At'
%         must be provided.
%     b0: m x 1 real,non-negative vector consists of all the measurements.
%     n:  The size of the unknown signal. It must be provided if A is a 
%         function handle.
%     isTruncated (boolean): If true, use the 'truncated' initializer that
%                            uses a sub-sample of the measurement.
%     isScaled (boolean):    If true, use a least-squares method to
%                            determine  the optimal scale of the
%                            initializer.
%
%     Note: When a function handle is used, the value of 'n' (the length of
%     the unknown signal) and 'At' (a function handle for the adjoint of
%     'A') must be supplied.  When 'A' is numeric, the values of 'At' and
%     'n' are ignored and inferred from the arguments.
%
%  Outputs:
%     x0:  A n x 1 vector. It is the guess generated by the spectral method
%          for  the unknown signal.
%  
%  See the script 'testInitNull.m' for an example of proper usage of this 
%  function.
%
%% Notations
%  A is A* in the paper and At is A in the paper. 
%  We use b0 rather than b in the paper for the measurements.
%  Other notations be consistent with the Null paper.
%  ai is the conjugate transpose of the ith row of A.
%   
%% Algorithm Description
%  (1) Split the indices of b0 into two subset I and its complement Ic,
%  where b(i) <= b(j) for all indices i in I and j in Ic. 
%  (2) Calculate the leading eigenvector of a matrix Y, where Y = At*Ic*A.
%  The method return this leading eigenvector, which is calcualted using 
%  Matlab's eigs() routine. 
%  
%  A short justification: If the size of the subset I is sufficiently
%  small, the set {ai} of vectors in A, for all i in I, will be nearly
%  orthogonal to x0. x0 = argmin( sum( norm(ai'*x)^2 ) for all i in I )
%  will then be a reasonable estimation for the unknown signal x. This can
%  be achieved by taking the leading eigenvector of the matrix Y.
% 
%  For detailed explanation, see Algorithm 1 in the Null paper.
%  
%  Note: (1) We switch the definition of A and At in the paper in our
%            implementation and comments. 
%  (2) In our implementation, we use matlab built-in function eigs() to get
%      the  leading eigenvector of the matrix Y rather than using the power
%      method used in both papers because eigs is believed to have better
%      performance in reality.
%  (3) We rescale the estimated x produced by the plain null initial method
%      in the end to make it have approximately the correct magnitude of
%      the unknown signal.
%  
%% References
%  Paper Title:   Phase Retrieval with One or Two Diffraction Patterns by Alternating 
%                 Projection with Null Initialization
%  Place:         Algorithm 1
%  Authors:       Pengwen Chen, Albert Fannjiang, Gi-Ren Liu
%  Arxiv Address: https://arxiv.org/abs/1510.07379
% 
%
% PhasePack by Rohan Chandra, Ziyuan Zhong, Justin Hontz, Val McCulloch,
% Christoph Studer, & Tom Goldstein 
% Copyright (c) University of Maryland, 2017

%% -----------------------------START----------------------------------


function [x0] = initOrthogonal(A, At, b0, n, verbose)

% If A is a matrix, infer n and At from A. Transform matrix into function form.
if isnumeric(A)
    m = size(A, 2);
    At = @(x) A' * x;
    A = @(x) A * x;
end

m = numel(b0);                % number of measurements

if ~exist('verbose','var') || verbose
    fprintf(['Estimating signal of length %d using a null ',...
         'initializer with %d measurements...\n'],n,m);
end

% gamma is the fraction of measurements that we use
gamma = 0.5;     % default value used in the Null paper

% Create mask in order to truncate the measurement matrix to store only
% those rows which correspond to the set of small values in b0.
[tmp,idx] = sort(b0,'descend');
I = zeros(m,1);
I(idx(round(m*gamma):end)) = 1;

% Our implemention uses Matlab's built-in function eigs() to get the leading 
% eigenvector because of greater efficiency.
% Create opts struct for eigs
opts = struct;
opts.isreal = false;

% Create function handle Yfunc, whose associated matrix is Y = At*Ic*A.
Yfunc = @(x) At(I.*A(x));

% Compute smallest Eigenvector of Yfunc
[x0,v] = eigs(Yfunc, n, 1, 'sr', opts);

% This part does not appear in the Null paper. We add it for better performance.
% Rescale the solution to have approximately the correct magnitude 
b = (1-I).*b0;
Ax = abs((1-I).*A(x0));
% Solve min_s || s|Ax| - b ||
s = Ax'*b/(Ax'*Ax);
x0 = s*x0;

if ~exist('verbose','var') || verbose
    fprintf('Initialization finished.\n');
end

end

