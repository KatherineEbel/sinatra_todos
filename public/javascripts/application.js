$(function () {
    $('form.delete').submit(function (event) {
        if (!confirm("This action cannot be undone. Are you sure?")) {
            return
        }
        event.preventDefault()
        const form = $(this)
        const request = $.ajax({
            url: form.attr("action"),
            method: "delete"
        })
        request.done(function (data, textStatus, { status}) {
            if (status === 204) {
                form.parent('li').remove()
            } else if (status === 200) {
                document.location = data
            }
        })
    })
})