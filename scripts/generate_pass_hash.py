import bcrypt
import sys


def main():
    # Read the password from the first command-line argument
    # and convert it to bytes (bcrypt operates on bytes, not strings)
    password = sys.argv[1].encode()

    # Continuously generate bcrypt hashes until one matches
    # our custom formatting constraint
    print("\nGenerating bcrypt hash with salt for password...")
    while True:
        # Generate a random salt (includes algorithm + cost factor)
        salt = bcrypt.gensalt()

        # Hash the password using the generated salt
        # Result is bytes, so decode to a UTF-8 string
        hashed = bcrypt.hashpw(password, salt).decode()

        # Split the hash on "$" and ensure every non-empty segment
        # starts with a digit (e.g., "2", "12", etc.)
        #
        # Example bcrypt format:
        #   $2b$12$<salt><hash>
        #
        # This check rejects hashes where a segment starts with a letter
        if all(part[0].isdigit() for part in hashed.split("$") if part):
            # Output both the original password and its hash
            print(f"\nPassword: {password.decode()}")
            print(f"Password hash: {hashed}")
            break


if __name__ == "__main__":
    main()
