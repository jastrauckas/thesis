function disc_data=CAIMe(xc,verbose)
%CAIM Algorithm
%Given: M examples described by continuous attributes Fi, S classes
%		For every Fi do: 
%Step 1 
%	1.1 find maximum (dn) and minimum (do) values
%	1.2 sort all distinct values of Fi in ascending order and initialize all possible interval 	boundaries, B, with the minimum, maximum, and all the midpoints of all adjacent pairs in the set 
%	1.3 set the initial discretization scheme to D:{[do,dn]}, set variable GlobalCAIM=0 
%Step 2 
%	2.1 initialize k=1 
%	2.2 tentatively add an inner boundary, which is not already in D, from set B, and calculate the corresponding CAIM value 
%	2.3 after all tentative additions have been tried, accept the one with the highest corresponding value of CAIM
%	2.4 if (CAIM >GlobalCAIM  or  k<S) then update D with the accepted, in step 2.3 boundary and set the GlobalCAIM=CAIM, otherwise terminate 
%	2.5 set k=k+1 and go to 2.2
%Result:	Discretization scheme D
%Paper: Kurgan, L. and Cios, K.J. (2002). CAIM Discretization Algorithm, IEEE Transactions of Knowledge and Data Engineering, 16(2): 145-153
%       xc: Continuous data + class label
%  verbose: Some process info
%disc_data: Discretized data
%This code is implemented by Fernando González, 2011/22/07
%ANY IMPROVEMNT, ERROR, CORRECTION..? PLEASE, LET ME KNOW to:ffgn2001@yahoo.com

    [N,L] = size(xc);           %L = TOTAL FEATURES + CLASS LABEL
    C=unique(xc(:,L),'rows');   %CLASS VECTOR
    S=length_row(C);            %NO. OF CLASSES

    disc_data=zeros(N,L-1);     %ALOCATE MEMORY TO DIZCRETIZED DATA

    
    %FOR EVERY VARIABLE DO
    for i=1:L-1
        if verbose
           fprintf('Processing %d',i);
        end
        
        %*******************************************
        %**               STEP 1                  **
        %*******************************************
        cont_data=sortrows(horzcat(xc(:,i),xc(:,L)),[1 2]);
        F(:,1)=unique(cont_data(:,1),'rows');  %SEARCH SPACE 
        F(:,2)=0;                              %FLAG 1="FEATURE SELECTED"
                                               %FLAG 0="NOT FEATURE SELECTED"
        size_F=length_row(F);                  %TOTAL BOUNDARIES
        d(1)=F(1,1);                           %MINIMUM
        d(2)=F(size_F,1);                      %MAXIMUM
        F(1,2)=1;                              %MINIMUM SELECTED
        F(size_F,2)=1;                         %MAXIMUM SELECTED
        GlobalCAIM=-Inf;                       %INITIALIZE GlobalCAIM
        
        %*******************************************
        %**               STEP 2                  **
        %*******************************************
        k=1;                                   %INITIALIZE k
        
        %CHECK IF ONLY BOUNDARY EXISTS, SO NO NEED TO WORK, ONLY ASSIGN 1
        if size_F==1
           keep_working=0;    
        else
           keep_working=1;
        end
 
        while keep_working                     %MAIN LOOP
            di_max_caim=0;                     %POINTER TO BEST BOUNDARY
            vCAIM=0;                           %CURRENT CAIM VALUE

            for j=1:size_F                     %TENTATIVELY ADD AN INNER BOUNDARY
                if ~F(j,2)                     %IF IS NOT ALREADY BEEN SELECTED
                   size_d=length_col(d);       %ACTUAL INTERVALS
                   td= [d F(j,1)];             %WORKING ON TEMPORAL AND INSERTS AN INTERVAL

                   td=sort(td);                %SORTING (ANY BETTER IDEA..!)
                   tabla_q=zeros(S,size_d);    %PREALLOCATE MEMORY 

                   %CREATE QUANTA MATRIX
                   for m=1:S
                       for t=1:size_d 
                           if t==1
                              tabla_q(m,t)=length_row(find((cont_data(:,2)==C(m)) &...
                                                          ((cont_data(:,1)>=td(t))&...
                                                          (cont_data(:,1)<=td(t+1)))));
                           else
                              tabla_q(m,t)=length_row(find((cont_data(:,2)==C(m)) &...
                                                          ((cont_data(:,1)>td(t)) &...
                                                          (cont_data(:,1)<=td(t+1)))));
                           end

                       end
                   end

                   %SORT IT TO MAKE IT EASY
                   tabla_q=sort(tabla_q,'descend');  

                   %CALCULATE CAIM VALUE
                   tCAIM=sum(tabla_q(1,:)./sum(tabla_q(:,[1:size_d])).*tabla_q(1,:))/size_d;

                   %ONE FOUND
                   if tCAIM>vCAIM
                      di_max_caim=j;           %KEEPS TRACK OF BEST BOUNDARY
                      vCAIM=tCAIM;             %KEEPS TRACK OF CAIM VALUE
                   end
                end 
            end                
            if di_max_caim>0                   %IF ONE IMPROVEMENT FOUND
                if vCAIM>GlobalCAIM || k<S  
                    d=[d F(di_max_caim,1)];    %ACCEPTED
                    d=sort(d);                 %SORTED
                    F(di_max_caim,2)=1;        %SET FLAG TO "SELECTED"
                    GlobalCAIM=vCAIM;          %SET GlobalCAIM 
                else
                    keep_working=0;            %STOP, NO IMPROVEMENT REACHED
                end
                k=k+1;
            else                        
               keep_working=0;                 %NO IMPROVEMENT FOUND (IT IS DIFFERENT...!)
            end
        end 

        %IF THERE IS TWO OR MORE BOUNDARIES, DISCRETIZE...!
        if size_F>1
            schemed=zeros(N,1);                %ALLOCATE MEMORY
            size_d=length_col(d);              %FINAL NO. OF BINS
            
            if verbose
               fprintf('...Intervals=%d GlobalCAIM=%.2f  [',size_d-1,GlobalCAIM);
               for k=1:size_d
                   fprintf('%3.2f ',d(k));
               end
               fprintf(']\n');
            end
            
            for j=1:size_d-1                   %DISCRETIZE
                if j==1 
                   indices=find(xc(:,i)>=d(j) & xc(:,i)<=d(j+1));
                else
                   indices=find(xc(:,i)>d(j) & xc(:,i)<=d(j+1));
                end
                schemed(indices)=j;
            end
        else
            schemed=ones(N,1); 
        end
        
        %STORE DISCRETIZED COLUMN
        disc_data(:,i)=schemed;
        
        %DO SOME CLEANING BEFORE NEXT VARIABLE (IT IS NEED IT, WHY?)
        clear F size_F d GlobalCAIM k di_max_caim vCAIM size_d td tabla_q;
    end

function [l]=length_row(m)

    [r,c] = size(m);
    l=r;
    
function [l]=length_col(m)

    [r,c] = size(m);
    l=c;