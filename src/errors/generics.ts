const fields = (item: string) => {
  return {
    REQUIRED: `fields.${item}.errors.required`,
    NOT_STRING: `fields.${item}.errors.notString`,
    TOO_SHORT: `fields.${item}.errors.tooShort`,
    NO_LETTER: `fields.${item}.errors.noLetter`,
    NO_DIGIT: `fields.${item}.errors.noDigit`,
    NO_SPECIAL_CHARACTER: `fields.${item}.errors.noSpecialCharacter`,
    HAS_SPACES: `fields.${item}.errors.hasSpaces`,
    NO_UPPERCASE: `fields.${item}.errors.noUppercase`,
    NOT_VALID: `fields.${item}.errors.notValid`,
    NOT_MATCH: `fields.${item}.errors.notMatch`,
    NOT_NUMBER: `fields.${item}.errors.notNumber`,
    NOT_URL: `fields.${item}.errors.notUrl`,
  };
};

const api = (item: string) => ({
  INTERNAL_SERVER_ERROR: `Internal server error on ${item}`,
  NOT_FOUND: `api.${item}.notFound`,
  EXIST: `api.${item}.exist`,
  NOT_ADMIN: `api.${item}.notAdmin`,
  NOT_FOUND_OR_WRONG_PASSWORD: `api.${item}.notFoundOrWrongPassword`,
  NOT_CREATED: `api.${item}.notCreated`,
  CANNOT_CHANGE_OWN_STATUS: `api.${item}.cannotChangeOwnStatus`,
  NOT_UPDATED: `api.${item}.notUpdated`,
  INVALID_FORMAT: `api.${item}.invalidFormat`,
  NOT_DELETED: `api.${item}.notDeleted`,
  UNDEFINED: `api.${item}.undefined`,
  ALREADY_CREATED: `api.${item}.alreadyCreated`,
  ALREADY_DONE: `api.${item}.alreadyDone`,
});

export const errorMessage = {
  fields,
  api,
};
