%This program finds parking lines with the Hough transform.
%Parking spots are found by moving over from line segment points.
%The main loop is designed for 2 rows of spaces with vertical cars.
%Spaces without both lines in the image will be ignored.
I = imread('Lot3.jpg');
G = rgb2gray(I);
BW = edge(G, 'Canny', 0.3);
[H, T, R] = hough(BW, 'Theta', -1:0.5:1);
P = houghpeaks(H, 8, 'threshold', ceil(0.3 * max(H(:))));
lines = houghlines(BW, T, R, P, 'FillGap', 5, 'MinLength', 7);
T = struct2table(lines);
sortedT = sortrows(T, 'rho');
sortedLines = table2struct(sortedT);
figure, imshow(BW),  figure, imshow(I),   hold on;
max_len = 0;  numOpen = 0;  percent1 = 0.05;
for k = 1 : length(lines)
  xy = [lines(k).point1; lines(k).point2];
  plot(xy(:, 1), xy(:, 2), 'LineWidth', 2, 'Color', 'blue');
  len = norm(lines(k).point1 - lines(k).point2);
  if len > max_len  %Check for longest segment
    max_len = len;
    xy_long = xy;
  end
end         
plot(xy_long(:, 1), xy_long(:, 2), 'LineWidth', 2, 'Color', 'red');
rho = 0;
for i = 1 : length(sortedLines) %run through entire Hough lines array
  if rho ~= sortedLines(i).rho  %if new rho segment, else move on
    rho = sortedLines(i).rho;
    u = i + 1;
    while u <= length(sortedLines) %Look for next rho in array
      if rho ~= sortedLines(u).rho %if found, now segment up then down
        nextRho = sortedLines(u).rho;
        deltaX = nextRho - rho;
        Seg = imcrop(BW, [sortedLines(i).point1(1) ...
                          sortedLines(i).point1(2) deltaX max_len]);
        check = mean2(Seg);
        if check < percent1 %percentage of 1s
          numOpen = numOpen + 1;
          X = [sortedLines(i).point1(1) ...
               sortedLines(i).point1(1) ...
               sortedLines(i).point1(1)+deltaX ...
               sortedLines(i).point1(1)+deltaX];
          Y = [sortedLines(i).point1(2) ...
               sortedLines(i).point1(2)+max_len ...
               sortedLines(i).point1(2)+max_len ...
               sortedLines(i).point1(2)];
          patch(X, Y, 'g', 'FaceAlpha', 0.3);
        end
        %Find lowest point for this rho and segment low space
        w = i;
        while rho == sortedLines(w).rho
          lowestPoint = sortedLines(w).point2;
          w = w + 1;
        end
        Seg = imcrop(BW, [lowestPoint(1) lowestPoint(2)-max_len ...
              deltaX   max_len]);
        check = mean2(Seg);
        if check < percent1 %percentage of 1s
          numOpen = numOpen + 1;                
          X = [lowestPoint(1)  lowestPoint(1) ...
               lowestPoint(1)+deltaX  lowestPoint(1)+deltaX];
          Y = [lowestPoint(2)  lowestPoint(2)-max_len ...
               lowestPoint(2)-max_len  lowestPoint(2)];
          patch(X, Y, 'g', 'FaceAlpha', 0.3);
        end
        break %Segmenting finished for this rho, now exit while loop
      end
      u = u + 1;
    end
  end              
end
hold off;
if numOpen == 1
  text = ' empty parking space has been detected.';
else
  text = ' empty parking spaces have been detected.';
end
disp([num2str(numOpen), text]);