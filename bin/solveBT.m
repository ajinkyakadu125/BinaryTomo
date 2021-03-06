function [xD,hist] = solveBT(A,b,options)
%solveBT A primal-dual algorithm to find a solution to
%
%   min_{x} 0.5*|x - b|_2^2 + |A'*x|_1
%
% Input:
%   A : a (tomography) matrix of size m x n
%   b : (tomographic) projection data vector of size m x 1
%   options:
%       maxIter : maximum number of iterations (default: 1e4)
%       optTol  : tolerance level for optimality (default: 1e-6)
%       progTol : tolerance level for progress (default: 1e-6)
%       saveHist: an indicator for saving history (default:0)
%
% Output:
%   xD : solution (size n x 1)
%   hist - history containing values at each iteration
%       f : function value 0.5|x-b|_2^2
%       g : function value |A'*x|_1
%       cost : sum of two functions f and g
%       er : iterates' progress, |[x;u]-[xp;up]|_2
%       opt : optimality, |x-b+A*u|_2
% 
%
% Created by:
%   - Ajinkya Kadu, Utrecht University
%   Feb 18, 2020

if nargin < 3
    options = [];
end

maxIter = getoptions(options,'maxIter',1e4);
optTol  = getoptions(options,'optTol',1e-6);
progTol = getoptions(options,'progTol',1e-6);
saveHist= getoptions(options,'saveHist',0);
updateG = getoptions(options,'updateGamma',1);


[m,n] = size(A);

x = zeros(m,1);
u = zeros(n,1);

gamma = 0.99/normest(A);
g1    = gamma;
g2    = gamma;

%%

for k=1:maxIter
    
    % update primal variable (x)
    xp = x;
    x  = proxf(xp-g1*(A*u),g1,b);
    
    
    % update dual variable (u)
    dx = xp-2*x;
    up = u;
    u = proxgd(up-g2*(A'*dx),g2);
    
    
    % history
    hist.er(k)   = norm([x;u]-[xp;up]);
    hist.opt(k)  = norm(x - b + A*u);
    if saveHist
        hist.f(k)    = 0.5*norm(x-b)^2;
        hist.g(k)    = norm(A'*x,1);
        hist.cost(k) = hist.f(k) + hist.g(k);
    end
    
    % update gamma
    if updateG
        Au = A*u;
        xAu= x'*(Au);
        normAu = norm(Au)^2;
        normAx = norm(A'*x)^2;
        if normAu > 0, g1 = xAu/normAu; end
        if normAx > 0, g2 = xAu/normAx; end
    end
    
    % optimality tolerance
    if (hist.opt(k) < optTol)
        fprintf('stopped at iteration %d \n',k);
        fprintf('Optimality: %d \n',hist.opt(k));
        fprintf('relative progress: %d \n',hist.er(k));
        break;
    end
    
    % progress tolerance
    if (hist.er(k) < progTol)
        fprintf('stopped at iteration %d \n',k);
        fprintf('relative progress: %d \n',hist.er(k));
        fprintf('Optimality: %d \n',hist.opt(k));
        break;
    end
    
    if k==maxIter
        fprintf('completed iterations %d. did not converge yet. \n',k);
        fprintf('Optimality: %d \n',hist.opt(k));
        fprintf('relative progress: %d \n',hist.er(k));
    end
    
end

xD = u;

end

function [y] = proxf(x,gamma,b)
% proximal for f(x) = 0.5*|x - b|^2

y = (x + gamma*b)/(1+gamma);

end

function [y] = proxgd(x,gamma)
% proximal for dual of function g(x) = |x|_1

y = x - gamma*proxg(x/gamma,1/gamma);

end

function [y] = proxg(x,gamma)
% proximal for function g(x) = |x|_1

y = max(0, x - gamma) - max(0, -x - gamma);

end

