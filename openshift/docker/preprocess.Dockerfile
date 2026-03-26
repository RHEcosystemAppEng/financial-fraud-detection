FROM rapidsai/base:25.08-cuda12.9-py3.12

WORKDIR /workspace

RUN pip install --no-cache-dir \
    category_encoders \
    networkx \
    matplotlib \
    scipy \
    scikit-learn>=1.6.1

COPY src/ /workspace/src/
COPY raw/card_transaction.v1.csv /workspace/raw/card_transaction.v1.csv

CMD ["python", "/workspace/src/preprocess_TabFormer_lp.py"]
