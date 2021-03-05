function Z=atomicNumber(element)
AtomicNumbers=readtable('AtomicNumbers.xlsx');
[rows,~]=size(AtomicNumbers);
for i=1:rows
    if startsWith(AtomicNumbers{i,3},element) && endsWith(AtomicNumbers{i,3},element)
            number=AtomicNumbers{i,1};
    end
end
Z=number;
end