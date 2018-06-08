function [ptsPixPosition, ptsId] = findLines (img,lnNames)
%User interface. User marks the edages of each line and the algorithm estimate the location of the  
% middle of the line using cross corelation with Gausian function.
%USAGE:
%   [ptsPixPosition, ptsId] = findLines (img,lnNames)
%INPUTS:
%   img - Histology fluorescence image with "bar cod" on it 
%   InNames- a strinf containin ght ename of the line (for example -x)
%  
%OUTPUTs
%   ptsPixPosition - containing position of lines identified (in pixels)
%   ptsId -  Vector of line identifier 
%   
%Example:
%   Let us assume 4 lines in the image:
%       n1,n2 parallel to y axis positioned in x=-50microns, x=+50 microns
%       n3,n4 parallel to x axis positioned in y=-50microns, y=+50 microns
% - The user will be asked to mark the edages of the lines (will apear as red lines)
% - The algorithm will compute the estimate location of the line (will apear as green line)
%Notice:
%       1) For each line edge mark points. Try to match between the y 
%         location of the lines edges at the first and last points.
%       2) double click to finish to mark an edge
%       3) use the 'delete' buttonin order to delete unwanted marked point 

% Reading the image
imagesc(img);
colormap gray;
resp= 'Y';
j=1;

while 1
    if strcmpi(resp,'N')
        break;
    end
 if mod(j, 2) == 0
       % Calculation the location of the line
       
       % Finding the average x and y points of the edges and plotting it
       x_av=mean(Points_temp_x(:,j-1:j),2);
       y_av=mean(Points_temp_y(:,j-1:j),2);
       hold on;
       plot(x_av,y_av,'b');
       % Estimating the X locations for different x points of the line
       % by comp[uting the cross correlation function of the image data
       % with gausian
   for i=1:length(Points_temp_x(:,j))
       dis=round(abs(Points_temp_x(i,j)-Points_temp_x(i,j-1)));
       intensity=mean(img(((round(y_av(i))):(round(y_av(i))+10)),((round(x_av(i))-3*dis):(round(x_av(i))+3*dis))));
       intensity=(intensity - min(intensity )) / ( max(intensity ) - min(intensity ) );
       intensity=smoothdata(smoothdata(intensity));
       var = maxGausVar(intensity,dis);
       Gaus= -1*gausswin([6*dis +1],var);
       Gaus=(Gaus - min(Gaus)) / ( max(Gaus) - min(Gaus) );
       [acor,lag] = xcorr(intensity,Gaus);
       [~,I] = max(abs(acor));
       lagDiff = lag(I);
       x_estimate(i)= x_av(i)-lagDiff+1;
   end
    x_estimate=x_estimate';
    p=polyfit(x_estimate,y_av,1);
    hold on;
    plot(x_estimate,p(1)*x_estimate+p(2),'g');
    ptsPixPosition_x(:,j/2)=[x_estimate];
    ptsPixPosition_y(:,j/2)=[p(1)*x_estimate+p(2)];
    ptsId(:,j/2)=repmat([j/2],[11,1]);
    j=j+1;
    resp = inputdlg('Do you wish to continue to mark lines? Y/N: ','s');
    clear x1; clear y1; clear x2; clear y2; clear Nx1; clear Ny1; clear Nx2; clear Ny2; 
    clear x_av; clear y_av; clear dis; clear intensity; clear gaus; clear acor; clear lag;
    clear I; clear lagDiff; clear x_estimate; clear p;
 else
     % Marking the edges of a line
     title(['Mark ' lnNames{round(j/2)} ' Left Side of the line. double click to finish']);
     [x1,y1] = getline;
     Nx1=length(x1);
     Ny1=length(y1);
     hold on
     plot(x1,y1,'r')
     [x2,y2] = getline;
     Nx2=length(x2);
     Ny2=length(y2);
     hold on
     plot(x2,y2,'r')
     j=j+1;
     Points_temp_x(:,j-1)=interp1([0:1:Nx1-1],x1,[0:(Nx1-1)/10:Nx1-1],'spline');
     Points_temp_y(:,j-1)=interp1([0:1:Ny1-1],y1,[0:(Ny1-1)/10:Ny1-1],'spline');
     Points_temp_x(:,j)=interp1([0:1:Nx2-1],x2,[0:(Nx2-1)/10:Nx2-1],'spline');
     Points_temp_y(:,j)=interp1([0:1:Ny2-1],y2,[0:(Ny2-1)/10:Ny2-1],'spline');
  end
end
ptsPixPosition=[ptsPixPosition_x(:) ptsPixPosition_y(:)];
ptsId=ptsId(:);
end
