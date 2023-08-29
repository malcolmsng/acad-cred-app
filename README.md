# Academic Credential App
Architecture and Design Document
https://docs.google.com/document/d/1AVUhcie2xlCitbXwlB-xDLjyHRMd0qOYrPwDXMzsWuQ/edit?usp=sharing 
## Setup

1. Install dependencies

```
npm install
```

## Build

`ci.yml` runs the following automatically.

1. Run the linter to ensure code is formatted correctly.

```
npm run lint
```

2. If there are formatting issues, run Prettier on all contracts using:

```
npm run prettier
```

3. Compile Truffle.

```
npx truffle compile
```

4. Run Truffle tests.

```
npx truffle test
```
