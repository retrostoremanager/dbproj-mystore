-- Create Game table
CREATE TABLE IF NOT EXISTS game (
    id            VARCHAR(100) PRIMARY KEY,
    title         VARCHAR(255) NOT NULL,
    console       VARCHAR(100) NOT NULL,
    release_date  DATE,
    publisher     VARCHAR(255),
    genre         VARCHAR(100),
    image_url     VARCHAR(500)
);

-- Create index on title
CREATE INDEX IF NOT EXISTS ix_game_title ON game(title);

-- Create index on console
CREATE INDEX IF NOT EXISTS ix_game_console ON game(console);

-- Add comment to table
COMMENT ON TABLE game IS 'Stores video game catalog information';
