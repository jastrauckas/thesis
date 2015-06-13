function [ DiscretData,QuantaMatrix ] = DiscretWithInterval( OriginalData,C,Column,DiscretInterval )
% C is the number of class variables.

M = size( OriginalData,1 );
k = length( DiscretInterval );
F = size( OriginalData,2 ) - C;
DiscretData = zeros( M,1 );
%Discrete the continuous data upon OriginalData 
for p = 1:M
    for t = 1:k
         if OriginalData( p,Column ) <= DiscretInterval( t )
             DiscretData( p ) = t-1;
             break;
         elseif OriginalData( p,Column ) > DiscretInterval( k )
             DiscretData( p ) = k;
         end             
     end        
end

%OriginalData( :,Column )
%Quanta matrix 
CState = C;
FState = length( DiscretInterval ) + 1;
QuantaMatrix = zeros( CState,FState );
for p = 1:M
    for q = 1:C
        if OriginalData( p,F+q ) == 1
           Row = q;
           Column = DiscretData( p )+1;
           QuantaMatrix( Row,Column ) = QuantaMatrix( Row,Column ) + 1;
        end
    end
end
%QuantaMatrix
end