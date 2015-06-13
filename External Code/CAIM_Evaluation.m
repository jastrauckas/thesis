function CAIMValue = CAIM_Evaluation( OriginalData, C, Feature, DiscretInterval )
%Paper: Kurgan, L. and Cios, K.J. (2002). CAIM Discretization Algorithm, IEEE Transactions of Knowledge and Data Engineering, 16(2): 145-153
% OriginalData is organized as F1,F2,...,Fm,C1,C2,...,Cn

k = length( DiscretInterval );
[ DiscretData,QuantaMatrix ] = DiscretWithInterval( OriginalData,C,Feature,DiscretInterval );
%Discrete the continuous data upon OriginalData 

%QuantaMatrix
% Compute the value of CAIM via quanta matrix and equation (sum maxr/Mr)/n 
SumQuantaMatrix = sum( QuantaMatrix,1 );
CAIMValue = 0 ;

for p = 1:k
    if max( QuantaMatrix(:,p) ) > 0
       CAIMValue = CAIMValue + ( max( QuantaMatrix(:,p) ) )^2/SumQuantaMatrix(p) ;
    end
end

CAIMValue = CAIMValue/k ;
end