function [ DiscreData,DiscretizationSet ] = CAIM_Discretization( OriginalData, C )
%CAIM Algorithm
%Given: M examples described by continuous attributes Fi, S classes
%		For every Fi do: 
%Step 1 
%	1.1 find maximum (dn) and minimum (do) values
%	1.2 sort all distinct values of Fi in ascending order and initialize all possible interval 	boundaries, B, with the minimum, maximum, and all the midpoints of all adjacent pairs in the set 
%	1.3 set the initial discretization scheme to D:{[do,dn]}, set variable GlobalCAIM=0 
%Step 2 
%	2.1 initialize k=1 
%	2.2 tentatively add an inner boundary, which is not already in D, from set B, and 	calculate the corresponding CAIM value 
%	2.3 after all tentative additions have been tried, accept the one with the highest 	corresponding value of CAIM
%	2.4 if (CAIM >GlobalCAIM  or  k<S) then update D with the accepted, in step 2.3, 	boundary and set the GlobalCAIM=CAIM, otherwise terminate 
%	2.5 set k=k+1 and go to 2.2
%Result:	Discretization scheme D 

%Paper: Kurgan, L. and Cios, K.J. (2002). CAIM Discretization Algorithm, IEEE Transactions of Knowledge and Data Engineering, 16(2): 145-153
% This code is implemented by Guangdi Li, 2009/06/04


% OriginalData is organized as F1,F2,...,Fm,C1,C2,...,Cn
F = size( OriginalData,2 ) - C ;
M = size( OriginalData,1 );
DiscreData = zeros( M,C+F ); 
DiscreData( :,F+1:F+C ) = OriginalData( :,F+1:F+C );
% Assume the maximum number of interval is M/(3*C)
MaxNumF = floor(M/(3*C));
% Save all the discretization intervals, which is saved in column
DiscretizationSet = zeros( MaxNumF,F );

for p = 1:F

    % Step 1
    %Dn = max( OriginalData( :,p )); % the maximum boundary 
    %Do = min( OriginalData( :,p )); % the minimum boundary   
    SortedInterval = unique( OriginalData( :,p ) );
    B = zeros( 1,length( SortedInterval )-1 );
    Len = length( B );
    for q = 1:Len
        B( q ) = ( SortedInterval( q ) + SortedInterval( q+1 ) )/ 2;
    end
    %B  
    D = zeros( 1,MaxNumF ); % D save all discretizations for variable Fi
    %D( 1 ) = Do; D( 2 ) = Dn; 
    GlobalCAIM = -Inf;
    
    %Step 2
    k=0; % save the number of discretizations in D, the initiate state is 2 
    while true
          CAIM = - Inf; Local = 0;
          for q = 1:Len
              if isempty( find( D( 1:k )==B(q), 1 ) ) == 1                  
                 DTemp = D;
                 DTemp( k+1 ) = B( q );
                 DTemp( 1:( k+1 ) ) = sort( DTemp( 1:( k+1 ) ) );
                 CAIMValue = CAIM_Evaluation( OriginalData,C,p,DTemp( 1:( k+1 ) ) );
                 if CAIM < CAIMValue 
                    CAIM = CAIMValue;
                    Local= q;
                 end           
              end        
          end
         % CAIM
         % GlobalCAIM
          if GlobalCAIM < CAIM && k < MaxNumF 
             GlobalCAIM = CAIM;
             k = k + 1;
             D( k ) = B( Local );
             D( 1:k ) = sort( D( 1:k ) );
          elseif  k <= MaxNumF && k <= C
             k = k + 1;
             D( k ) = B( Local );
             D( 1:k ) = sort( D( 1:k ) );              
          else
              break;
          end   
    end
    DiscretizationSet( 1:k,p )= D( 1:k )';
    % do the discretization process according to intervals in D. 
    DiscreData( :,p ) = DiscretWithInterval( OriginalData,C,p,D( 1:k ) );
    
end

end