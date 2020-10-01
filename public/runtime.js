(function() {

    this.el = this.el || {};
    
    function callAction(actionId, element) {
        console.log('calling action', actionId, element);
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log('response:', xhr.responseText);
            }
            else {
                console.error("Something's wrong");
            }
        };
        xhr.open('POST', '/action/' + actionId);
        xhr.send();
    }

    this.el.actions = {
        call: callAction
    };

}.call(window));