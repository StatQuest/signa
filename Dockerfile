# Use the official Python 3.11 image
FROM python:3.11

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    POETRY_VERSION=1.8.2 \
    POETRY_VIRTUALENVS_CREATE=false \
    PATH="/root/.local/bin:$PATH"

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    chmod +x /root/.local/bin/poetry && \
    ln -s /root/.local/bin/poetry /usr/local/bin/poetry

# Set working directory
WORKDIR /notebooks

# Copy all repo files into /notebooks/
COPY . /notebooks/

# Install dependencies using Poetry
RUN poetry install --no-root

# Expose Jupyter Notebook port
EXPOSE 8888

# Run Jupyter when the container starts
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--NotebookApp.token=''"]
