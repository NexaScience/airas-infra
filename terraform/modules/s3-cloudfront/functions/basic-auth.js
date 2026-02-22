function handler(event) {
    var request = event.request;
    var headers = request.headers;
    var authString = "Basic ${credentials}";

    if (
        typeof headers.authorization === "undefined" ||
        headers.authorization.value !== authString
    ) {
        return {
            statusCode: 401,
            statusDescription: "Unauthorized",
            headers: {
                "www-authenticate": { value: "Basic realm=\"Dev Environment\"" }
            }
        };
    }

    return request;
}
