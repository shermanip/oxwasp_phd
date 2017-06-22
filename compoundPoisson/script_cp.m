clc;
clearvars;
close all;

lambda = 1;
alpha = 1;
beta = 1;

n = 10000;

Y = poissrnd(lambda,n,1); %simulate latent poisson variables
X = gamrnd(Y*alpha,1/beta); %simulate observable gamma

lambda_predict = lambda;
alpha_predict = alpha;
beta_predict = beta;
Y_predict = zeros(n,1);

for step = 1:5
    for i = 1:n
        Y_predict(i) = EStep(X(i), lambda_predict, alpha_predict, beta_predict);
    end
    for i = 1:10
        [lambda_predict, alpha_predict, beta_predict] = MStep(X, Y_predict, alpha_predict, beta_predict);
    end
end

zero_index = (X==0);
n_0 = sum(zero_index);
X_no_0 = X(~zero_index);

x_range = linspace(min(X_no_0),max(X_no_0),500);
pdf_range = zeros(1,numel(x_range));
pdf_predict_range = zeros(1,numel(x_range));
for i = 1:numel(pdf_range)
    pdf_range(i) = cpPdf(x_range(i),lambda,alpha,beta);
    pdf_predict_range(i) = cpPdf(x_range(i),lambda_predict,alpha_predict,beta_predict);
end
p_0 = exp(-lambda);
p_0_predict = exp(-lambda_predict);

figure;
yyaxis left;
h = histogram(X_no_0,'Normalization','CountDensity');
hold on;
scatter(h.BinWidth/2,n_0/h.BinWidth,50,'filled','b');

plot(x_range,pdf_range*(n),'r-');
scatter(0,n*p_0/h.BinWidth,50,'filled','r');

plot(x_range,pdf_predict_range*(n),'g-');
scatter(h.BinWidth,n*p_0_predict/h.BinWidth,50,'filled','g');

plot([h.BinWidth/2,h.BinWidth/2],[0,n_0/h.BinWidth],'b');
plot([0,0],[0,n*p_0/h.BinWidth],'r');
plot([h.BinWidth,h.BinWidth],[0,n*p_0_predict/h.BinWidth],'g');

xlim([min(X),max(X)]);
y_density_lim = ylim;
ylabel('frequency density');
yyaxis right;
ylim([0,y_density_lim(2)*h.BinWidth]);
ylabel('frequency');
xlabel('support');
legend('Real simulation','Zero simulation','Real density','Zero mass');